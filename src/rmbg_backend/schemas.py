from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Any


class OutputFormat(str, Enum):
    PNG = "png"
    JPEG = "jpeg"
    WEBP = "webp"
    TIFF = "tiff"

    @property
    def extension(self) -> str:
        return {
            OutputFormat.PNG: ".png",
            OutputFormat.JPEG: ".jpg",
            OutputFormat.WEBP: ".webp",
            OutputFormat.TIFF: ".tiff",
        }[self]

    @property
    def pillow_format(self) -> str:
        return {
            OutputFormat.PNG: "PNG",
            OutputFormat.JPEG: "JPEG",
            OutputFormat.WEBP: "WEBP",
            OutputFormat.TIFF: "TIFF",
        }[self]

    @property
    def supports_alpha(self) -> bool:
        return self in {OutputFormat.PNG, OutputFormat.WEBP, OutputFormat.TIFF}


@dataclass(frozen=True)
class ProcessingOptions:
    output_dir: Path | None = None
    suffix: str = "_rmbg"
    output_format: OutputFormat = OutputFormat.PNG
    background_color: str | None = None
    overwrite: bool = False
    save_alpha_mask: bool = False
    save_preview: bool = False
    preview_background: str = "#f2f2f7"

    def __post_init__(self) -> None:
        output_format = OutputFormat(self.output_format)
        object.__setattr__(self, "output_format", output_format)
        if not output_format.supports_alpha and self.background_color is None:
            raise ValueError(
                f"{output_format.value} output requires --background-color because it cannot store alpha."
            )


@dataclass(frozen=True)
class ProcessingResult:
    input_path: Path
    output_path: Path
    alpha_mask_path: Path | None
    preview_path: Path | None
    width: int
    height: int
    duration_seconds: float

    def to_dict(self) -> dict[str, Any]:
        return {
            "input_path": str(self.input_path),
            "output_path": str(self.output_path),
            "alpha_mask_path": _path_or_none(self.alpha_mask_path),
            "preview_path": _path_or_none(self.preview_path),
            "width": self.width,
            "height": self.height,
            "duration_seconds": self.duration_seconds,
        }


def _path_or_none(path: Path | None) -> str | None:
    return str(path) if path is not None else None
