from pydantic import BaseModel, Field
from typing import Optional


class QueryRequest(BaseModel):
    question: str = Field(..., min_length=3)
    top_k: int = Field(default=4, ge=1, le=8)


class IndexResponse(BaseModel):
    status: str
    documents_indexed: int
    chunks_indexed: int


class ChunkMetadata(BaseModel):
    doc_id: str
    chunk_id: str
    file_path: str
    content_hash: str
    embedding_model: str
    embedding_version: str
    text: str


class HealthResponse(BaseModel):
    status: str