from pathlib import Path
from tempfile import TemporaryDirectory
from unittest import TestCase, main

from rmbg_backend.batch import BatchOptions, BatchProcessor
from rmbg_backend.schemas import ProcessingResult


class FakeProcessor:
    def process_file(self, input_path: Path, _options: BatchOptions) -> ProcessingResult:
        if input_path.name == "bad.jpg":
            raise ValueError("broken")
        return ProcessingResult(
            input_path=input_path,
            output_path=input_path.with_suffix(".png"),
            alpha_mask_path=None,
            preview_path=None,
            width=1,
            height=1,
            duration_seconds=0.1,
        )


class BatchTests(TestCase):
    def test_batch_continues_after_item_failure(self) -> None:
        with TemporaryDirectory() as temp_dir:
            tmp_path = Path(temp_dir)
            good = tmp_path / "good.jpg"
            bad = tmp_path / "bad.jpg"
            good.write_bytes(b"")
            bad.write_bytes(b"")
            progress: list[tuple[int, int]] = []

            batch = BatchProcessor(FakeProcessor())  # type: ignore[arg-type]
            results = batch.process_paths(
                [tmp_path],
                BatchOptions(output_dir=tmp_path),
                on_progress=lambda done, total, _item: progress.append((done, total)),
            )

            self.assertEqual(len(results), 2)
            self.assertEqual([item.error for item in results], ["broken", None])
            self.assertEqual(progress, [(0, 2), (1, 2), (2, 2)])


if __name__ == "__main__":
    main()
