import json
from pathlib import Path
from typing import List, Dict, Any
import faiss


def save_metadata(path: Path, metadata: List[Dict[str, Any]]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)


def load_metadata(path: Path) -> List[Dict[str, Any]]:
    if not path.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_faiss_index(index: faiss.Index, path: Path) -> None:
    faiss.write_index(index, str(path))


def load_faiss_index(path: Path):
    if not path.exists():
        return None
    return faiss.read_index(str(path))