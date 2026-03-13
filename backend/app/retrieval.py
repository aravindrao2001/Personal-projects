from typing import List, Dict, Tuple
from functools import lru_cache

import numpy as np
import faiss
from sentence_transformers import SentenceTransformer

from app.config import EMBEDDING_MODEL

_embedder = None


def get_embedder() -> SentenceTransformer:
    global _embedder
    if _embedder is None:
        _embedder = SentenceTransformer(EMBEDDING_MODEL)
    return _embedder


def embed_texts(texts: List[str]) -> np.ndarray:
    model = get_embedder()
    vectors = model.encode(texts, normalize_embeddings=True)
    return np.array(vectors, dtype="float32")


@lru_cache(maxsize=512)
def embed_single_text(text: str) -> Tuple[float, ...]:
    model = get_embedder()
    vector = model.encode([text], normalize_embeddings=True)[0]
    return tuple(float(x) for x in vector)


def build_faiss_index(chunks: List[Dict]) -> faiss.Index:
    texts = [chunk["text"] for chunk in chunks]
    embeddings = embed_texts(texts)

    dim = embeddings.shape[1]
    index = faiss.IndexFlatIP(dim)
    index.add(embeddings)
    return index


def search_index(
    index: faiss.Index,
    metadata: List[Dict],
    question: str,
    top_k: int
) -> List[Tuple[Dict, float]]:
    query_vector = np.array([embed_single_text(question)], dtype="float32")
    scores, indices = index.search(query_vector, top_k)

    results: List[Tuple[Dict, float]] = []
    for idx, score in zip(indices[0], scores[0]):
        if idx == -1:
            continue
        results.append((metadata[idx], float(score)))

    return results