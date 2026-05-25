from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path


DEFAULT_MODEL_ID = "briaai/RMBG-2.0"
DEFAULT_IMAGE_SIZE = 1024
DEFAULT_HF_HOME_NAME = ".hf_home"


@dataclass(frozen=True)
class BackendConfig:
    model_id: str = DEFAULT_MODEL_ID
    image_size: int = DEFAULT_IMAGE_SIZE
    cache_dir: Path | None = None
    hf_home: Path | None = None


def ensure_hf_home(hf_home: Path | None = None) -> Path | None:
    if "HF_HOME" in os.environ:
        return Path(os.environ["HF_HOME"]).expanduser()

    resolved = Path(hf_home).expanduser() if hf_home is not None else resolve_default_hf_home()
    if resolved is not None:
        os.environ["HF_HOME"] = str(resolved)
    return resolved


def resolve_default_hf_home() -> Path | None:
    configured = os.environ.get("RMBG_HF_HOME")
    if configured:
        return Path(configured).expanduser()

    cwd_home = Path.cwd() / DEFAULT_HF_HOME_NAME
    if cwd_home.exists():
        return cwd_home

    source_home = Path(__file__).resolve().parents[2] / DEFAULT_HF_HOME_NAME
    if source_home.exists():
        return source_home

    return None
