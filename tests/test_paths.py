from pathlib import Path
from unittest import TestCase, main

from rmbg_backend.paths import build_output_path, discover_images


class PathTests(TestCase):
    def test_build_output_path_adds_counter_when_file_exists(self) -> None:
        from tempfile import TemporaryDirectory

        with TemporaryDirectory() as temp_dir:
            tmp_path = Path(temp_dir)
            source = tmp_path / "photo.jpg"
            source.write_bytes(b"input")
            existing = tmp_path / "photo_rmbg.png"
            existing.write_bytes(b"output")

            output = build_output_path(
                source,
                output_dir=None,
                suffix="_rmbg",
                extension=".png",
                overwrite=False,
            )

            self.assertEqual(output, tmp_path / "photo_rmbg_1.png")

    def test_discover_images_filters_supported_extensions(self) -> None:
        from tempfile import TemporaryDirectory

        with TemporaryDirectory() as temp_dir:
            tmp_path = Path(temp_dir)
            (tmp_path / "a.jpg").write_bytes(b"")
            (tmp_path / "b.txt").write_text("ignore")
            (tmp_path / "c.PNG").write_bytes(b"")

            self.assertEqual(discover_images(tmp_path), [tmp_path / "a.jpg", tmp_path / "c.PNG"])


if __name__ == "__main__":
    main()
