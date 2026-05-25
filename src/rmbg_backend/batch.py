from __future__ import annotations

from collections.abc import Callable, Iterable
from dataclasses import dataclass
from pathlib import Path
from time import perf_counter
from typing import TYPE_CHECKING, Any

from rmbg_backend.paths import discover_images
from rmbg_backend.schemas import ProcessingOptions, ProcessingResult

if TYPE_CHECKING:
    from rmbg_backend.processor import ImageProcessor


@dataclass(frozen=True)
class BatchOptions(ProcessingOptions):
    recursive: bool = False


@dataclass(frozen=True)
class BatchItemResult:
    input_path: Path
    result: ProcessingResult | None
    error: str | None

    def to_dict(self) -> dict[str, Any]:
        return {
            "input_path": str(self.input_path),
            "result": self.result.to_dict() if self.result is not None else None,
            "error": self.error,
        }


ProgressCallback = Callable[[int, int, BatchItemResult | None], None]


class BatchProcessor:
    def __init__(self, processor: ImageProcessor) -> None:
        self.processor = processor

    def process_paths(
        self,
        inputs: Iterable[Path | str],
        options: BatchOptions,
        on_progress: ProgressCallback | None = None,
    ) -> list[BatchItemResult]:
        image_paths: list[Path] = []
        for item in inputs:
            image_paths.extend(discover_images(Path(item), recursive=options.recursive))

        total = len(image_paths)
        results: list[BatchItemResult] = []
        if on_progress is not None:
            on_progress(0, total, None)

        for index, path in enumerate(image_paths, start=1):
            try:
                result = self.processor.process_file(path, options)
                item = BatchItemResult(input_path=path, result=result, error=None)
            except Exception as exc:  # noqa: BLE001 - batch jobs should continue per file.
                item = BatchItemResult(input_path=path, result=None, error=str(exc))

            results.append(item)
            if on_progress is not None:
                on_progress(index, total, item)

        return results

    def process_paths_with_timing(
        self,
        inputs: Iterable[Path | str],
        options: BatchOptions,
        on_progress: ProgressCallback | None = None,
    ) -> tuple[list[BatchItemResult], float]:
        started = perf_counter()
        results = self.process_paths(inputs, options, on_progress)
        return results, perf_counter() - started
