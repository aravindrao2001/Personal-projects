import numpy as np

from app.retrieval import build_faiss_index, search_index


def test_search_index_returns_relevant_results(monkeypatch):
    def fake_embed_texts(texts):
        vectors = []
        for text in texts:
            t = text.lower()
            if "annual leave" in t or "leave days" in t:
                vectors.append([1.0, 0.0, 0.0])
            elif "sick leave" in t:
                vectors.append([0.0, 1.0, 0.0])
            else:
                vectors.append([0.0, 0.0, 1.0])
        return np.array(vectors, dtype="float32")

    def fake_embed_single_text(text):
        t = text.lower()
        if "annual leave" in t or "leave days" in t:
            return (1.0, 0.0, 0.0)
        elif "sick leave" in t:
            return (0.0, 1.0, 0.0)
        return (0.0, 0.0, 1.0)

    monkeypatch.setattr("app.retrieval.embed_texts", fake_embed_texts)
    monkeypatch.setattr("app.retrieval.embed_single_text", fake_embed_single_text)

    chunks = [
        {
            "chunk_id": "1",
            "doc_id": "doc1",
            "file_path": "policy.txt",
            "text": "Employees get 24 days of annual leave per year.",
        },
        {
            "chunk_id": "2",
            "doc_id": "doc1",
            "file_path": "policy.txt",
            "text": "Employees may take up to 10 days of paid sick leave annually.",
        },
    ]

    index = build_faiss_index(chunks)
    results = search_index(index, chunks, "How many annual leave days do employees get?", top_k=2)

    assert len(results) > 0

    top_chunk, top_score = results[0]
    assert "annual leave" in top_chunk["text"].lower()
    assert isinstance(top_score, float)
    assert top_score > 0