from pathlib import Path
from unittest import TestCase, main

from rmbg_backend.schemas import OutputFormat, ProcessingOptions, ProcessingResult


class SchemaTests(TestCase):
    def test_jpeg_requires_background_color(self) -> None:
        with self.assertRaises(ValueError):
            ProcessingOptions(output_format=OutputFormat.JPEG)

    def test_result_serializes_paths(self) -> None:
        result = ProcessingResult(
            input_path=Path("input.jpg"),
            output_path=Path("output.png"),
            alpha_mask_path=None,
            preview_path=Path("preview.jpg"),
            width=10,
            height=20,
            duration_seconds=0.5,
        )

        self.assertEqual(
            result.to_dict(),
            {
                "input_path": "input.jpg",
                "output_path": "output.png",
                "alpha_mask_path": None,
                "preview_path": "preview.jpg",
                "width": 10,
                "height": 20,
                "duration_seconds": 0.5,
            },
        )


if __name__ == "__main__":
    main()
