import re
from typing import List, Dict, Generator
import ollama


def build_prompt(question: str, retrieved_chunks: List[Dict]) -> str:
    context_blocks = []
    for i, chunk in enumerate(retrieved_chunks, start=1):
        context_blocks.append(
            f"[{i}] File: {chunk['file_path']}\n"
            f"Chunk ID: {chunk['chunk_id']}\n"
            f"Text: {chunk['text']}"
        )

    context = "\n\n".join(context_blocks)

    return f"""
You are a grounded document QA assistant.

Rules:
- Answer only from the provided context.
- Use citations only from the provided excerpt IDs, like [1] or [2].
- Do not invent facts.
- Do not invent citations.
- If the answer is not supported by the context, say exactly:
I could not find enough support in the indexed documents to answer confidently.
- Keep the answer concise and useful.

Question:
{question}

Context:
{context}
""".strip()


def validate_citations(answer: str, retrieved_chunks: List[Dict]) -> str:
    valid_ids = {str(i) for i in range(1, len(retrieved_chunks) + 1)}
    cited_ids = re.findall(r"\[(\d+)\]", answer)

    if any(cid not in valid_ids for cid in cited_ids):
        return "I could not find enough support in the indexed documents to answer confidently."

    return answer


def stream_generate(question: str, retrieved_chunks: List[Dict], model: str) -> Generator[str, None, None]:
    prompt = build_prompt(question, retrieved_chunks)

    stream = ollama.chat(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        stream=True,
    )

    full_text = ""
    for chunk in stream:
        token = chunk.get("message", {}).get("content", "")
        if token:
            full_text += token

    full_text = validate_citations(full_text, retrieved_chunks)
    yield full_text