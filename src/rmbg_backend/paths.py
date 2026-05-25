from __future__ import annotations

from pathlib import Path


SUPPORTED_INPUT_EXTENSIONS = {
    ".bmp",
    ".heic",
    ".heif",
    ".jpeg",
    ".jpg",
    ".png",
    ".tif",
    ".tiff",
    ".webp",
}


def is_supported_image(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in SUPPORTED_INPUT_EXTENSIONS


def discover_images(path: Path, recursive: bool = False) -> list[Path]:
    candidate = Path(path).expanduser()
    if is_supported_image(candidate):
        return [candidate]
    if not candidate.is_dir():
        raise FileNotFoundError(f"Input does not exist or is not a supported image: {candidate}")

    iterator = candidate.rglob("*") if recursive else candidate.iterdir()
    return sorted(item for item in iterator if is_supported_image(item))


def build_output_path(
    input_path: Path,
    output_dir: Path | None,
    suffix: str,
    extension: str,
    overwrite: bool,
) -> Path:
    target_dir = Path(output_dir).expanduser() if output_dir is not None else input_path.parent
    extension = extension if extension.startswith(".") else f".{extension}"
    base = target_dir / f"{input_path.stem}{suffix}{extension}"
    if overwrite or not base.exists():
        return base

    counter = 1
    while True:
        candidate = target_dir / f"{input_path.stem}{suffix}_{counter}{extension}"
        if not candidate.exists():
            return candidate
        counter += 1
