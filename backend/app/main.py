#print("DEBUG MAIN.PY LOADED")
import json
import time
import uuid
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse

from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import (
    FAISS_PATH,
    METADATA_PATH,
    OLLAMA_MODEL,
    DEFAULT_TOP_K,
    MAX_TOP_K,
    RETRIEVAL_CONFIDENCE_THRESHOLD,
)
from app.schemas import QueryRequest, IndexResponse, HealthResponse
from app.ingest import build_chunks
from app.retrieval import build_faiss_index, search_index
from app.storage import save_metadata, load_metadata, save_faiss_index, load_faiss_index
from app.llm import stream_generate
from app.safety import sanitize_user_input

limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title="Ask Docs Local LLM")
app.state.limiter = limiter

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(
        status_code=429,
        content={"detail": "Rate limit exceeded"},
    )


@app.get("/health", response_model=HealthResponse)
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    return {"status": "ready"}


@app.post("/index", response_model=IndexResponse)
@limiter.limit("10/minute")
def index_docs(request: Request):
    request_id = str(uuid.uuid4())
    start = time.perf_counter()

    chunks = build_chunks()
    if not chunks:
        return {
            "status": "no_documents_found",
            "documents_indexed": 0,
            "chunks_indexed": 0,
        }

    index = build_faiss_index(chunks)
    save_faiss_index(index, FAISS_PATH)
    save_metadata(METADATA_PATH, chunks)

    doc_count = len({chunk["doc_id"] for chunk in chunks})
    elapsed_ms = round((time.perf_counter() - start) * 1000, 2)

    print(json.dumps({
        "request_id": request_id,
        "event": "index_completed",
        "documents_indexed": doc_count,
        "chunks_indexed": len(chunks),
        "timing_ms": elapsed_ms,
    }))

    return {
        "status": "success",
        "documents_indexed": doc_count,
        "chunks_indexed": len(chunks),
    }


@app.post("/query")
@limiter.limit("30/minute")
def query_docs(request: Request, payload: QueryRequest):
    #print("QUERY ENDPOINT HIT")
    request_id = str(uuid.uuid4())
    question = sanitize_user_input(payload.question)
    top_k = min(payload.top_k or DEFAULT_TOP_K, MAX_TOP_K)

    index = load_faiss_index(FAISS_PATH)
    metadata = load_metadata(METADATA_PATH)

    if index is None or not metadata:
        raise HTTPException(status_code=400, detail="Index not built. Run POST /index first.")

    retrieval_start = time.perf_counter()
    results = search_index(index, metadata, question, top_k)
    print("Retrieved results:", results)

    if results:
      print("Top score:", results[0][1])
      print("Top chunk:", results[0][0]["text"])
    retrieval_ms = round((time.perf_counter() - retrieval_start) * 1000, 2)

    print(json.dumps({
        "request_id": request_id,
        "event": "retrieval_completed",
        "question": question,
        "top_k": top_k,
        "result_count": len(results),
        "timing_ms": retrieval_ms,
    }))

    def sse(event_name: str, data: dict) -> str:
        return f"event: {event_name}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"

    if not results:
        def no_results_stream():
            message = (
                "Unsupported question.\n\n"
                "You can ask questions about topics such as:\n"
                "• employee leave policies\n"
                "• sick leave limits\n"
                "• benefits and insurance\n"
                "• professional development support"
            )
            yield sse("retrieval_error", {"message": message})
            yield sse("done", {"status": "ok"})
        return StreamingResponse(no_results_stream(), media_type="text/event-stream")

    top_score = results[0][1]
    retrieved_chunks = [item[0] for item in results]

    if top_score < RETRIEVAL_CONFIDENCE_THRESHOLD:
        def unsupported_stream():
            message = (
                "Unsupported question.\n\n"
                "You can ask questions about topics such as:\n"
                "• employee leave policies\n"
                "• sick leave limits\n"
                "• benefits and insurance\n"
                "• professional development support"
            )
            yield sse("retrieval_error", {"message": message})
            yield sse("done", {"status": "ok"})
        return StreamingResponse(unsupported_stream(), media_type="text/event-stream")

    def event_stream():
        gen_start = time.perf_counter()

        token_budget = {
            "used": sum(len(chunk["text"]) for chunk in retrieved_chunks) // 4,
            "max": 4096,
        }
        yield sse("meta", {"request_id": request_id, "token_budget": token_budget})

        for idx, chunk in enumerate(retrieved_chunks[:2], start=1):
            citation = {
                "id": idx,
                "file": Path(chunk["file_path"]).name,
                "snippet": chunk["text"][:240].replace("\n", " "),
                "chunkId": chunk["chunk_id"],
            }
            yield sse("citation", citation)

        try:
            for token in stream_generate(question, retrieved_chunks[:top_k], model=OLLAMA_MODEL):
                yield sse("token", {"text": token})
        except Exception as exc:
            yield sse("model_error", {"message": str(exc)})
            yield sse("done", {"status": "ok"})
            return

        generation_ms = round((time.perf_counter() - gen_start) * 1000, 2)
        print(json.dumps({
            "request_id": request_id,
            "event": "generation_completed",
            "timing_ms": generation_ms,
        }))

        yield sse("done", {"status": "ok"})

    return StreamingResponse(event_stream(), media_type="text/event-stream")