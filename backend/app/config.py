from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
DOCS_DIR = BASE_DIR / "docs"
DATA_DIR = BASE_DIR / "data"

FAISS_PATH = DATA_DIR / "index.faiss"
METADATA_PATH = DATA_DIR / "metadata.json"

EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
EMBEDDING_VERSION = "all-MiniLM-L6-v2"
OLLAMA_MODEL = "mistral"

CHUNK_SIZE = 900
CHUNK_OVERLAP = 150

MAX_TOP_K = 8
DEFAULT_TOP_K = 4
RETRIEVAL_CONFIDENCE_THRESHOLD = 0.20

MAX_FILE_SIZE_MB = 10
MAX_CHUNKS = 5000

DATA_DIR.mkdir(parents=True, exist_ok=True)
DOCS_DIR.mkdir(parents=True, exist_ok=True)