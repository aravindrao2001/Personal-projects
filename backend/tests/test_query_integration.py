from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_query_streams_tokens_and_citations(monkeypatch):
    fake_results = [
        (
            {
                "chunk_id": "doc_1_chunk_1",
                "doc_id": "doc_1",
                "file_path": "policy.txt",
                "text": "Full-time employees are entitled to 24 days of annual leave per year.",
            },
            0.95,
        ),
        (
            {
                "chunk_id": "doc_1_chunk_2",
                "doc_id": "doc_1",
                "file_path": "policy.txt",
                "text": "Employees may take up to 10 days of paid sick leave annually.",
            },
            0.90,
        ),
    ]

    class DummyIndex:
        pass

    def fake_load_faiss_index(_):
        return DummyIndex()

    def fake_load_metadata(_):
        return [item[0] for item in fake_results]

    def fake_search_index(index, metadata, question, top_k):
        return fake_results[:top_k]

    def fake_stream_generate(question, retrieved_chunks, model):
        yield "Employees get 24 days of annual leave per year [1]."

    monkeypatch.setattr("app.main.load_faiss_index", fake_load_faiss_index)
    monkeypatch.setattr("app.main.load_metadata", fake_load_metadata)
    monkeypatch.setattr("app.main.search_index", fake_search_index)
    monkeypatch.setattr("app.main.stream_generate", fake_stream_generate)

    response = client.post(
        "/query",
        json={"question": "How many annual leave days do employees get?", "top_k": 2},
    )

    assert response.status_code == 200
    assert "text/event-stream" in response.headers["content-type"]

    body = response.text
    assert "event: meta" in body
    assert "event: citation" in body
    assert '"file": "policy.txt"' in body
    assert '"chunkId": "doc_1_chunk_1"' in body
    assert "event: token" in body
    assert "24 days of annual leave" in body
    assert "event: done" in body