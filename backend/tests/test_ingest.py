from app.ingest import chunk_text


def test_chunk_text_splits_long_text():
    text = "A" * 2000
    chunks = chunk_text(text, chunk_size=900, overlap=150)

    assert len(chunks) >= 2
    assert all(isinstance(chunk, str) for chunk in chunks)
    assert all(len(chunk) > 0 for chunk in chunks)
    assert all(len(chunk) <= 900 for chunk in chunks)


def test_chunk_text_respects_overlap():
    text = "A" * 1200
    chunks = chunk_text(text, chunk_size=900, overlap=150)

    assert len(chunks) == 2
    assert chunks[0][-150:] == chunks[1][:150]