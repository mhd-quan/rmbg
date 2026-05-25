from __future__ import annotations

from pathlib import Path
from time import perf_counter

from PIL import Image, ImageOps

from rmbg_backend.engine import RmbgEngine
from rmbg_backend.paths import build_output_path
from rmbg_backend.preview import flatten_on_color, make_side_by_side_preview
from rmbg_backend.schemas import ProcessingOptions, ProcessingResult

try:
    from pillow_heif import register_heif_opener
except ImportError:
    register_heif_opener = None
else:
    register_heif_opener()


class ImageProcessor:
    def __init__(self, engine: RmbgEngine) -> None:
        self.engine = engine

    def process_file(self, input_path: Path | str, options: ProcessingOptions) -> ProcessingResult:
        source = Path(input_path).expanduser()
        output_path = build_output_path(
            source,
            output_dir=options.output_dir,
            suffix=options.suffix,
            extension=options.output_format.extension,
            overwrite=options.overwrite,
        )
        output_path.parent.mkdir(parents=True, exist_ok=True)

        started = perf_counter()
        image = self._open_image(source)
        alpha = self.engine.predict_alpha(image)
        cutout = image.convert("RGBA")
        cutout.putalpha(alpha)

        if options.background_color is None:
            result = cutout
        else:
            result = flatten_on_color(cutout, options.background_color)
        result.save(output_path, format=options.output_format.pillow_format)

        alpha_path: Path | None = None
        if options.save_alpha_mask:
            alpha_path = output_path.with_name(f"{output_path.stem}_alpha.png")
            if alpha_path.exists() and not options.overwrite:
                alpha_path = build_output_path(
                    alpha_path,
                    output_dir=alpha_path.parent,
                    suffix="",
                    extension=".png",
                    overwrite=False,
                )
            alpha.save(alpha_path, format="PNG")

        preview_path: Path | None = None
        if options.save_preview:
            preview_path = output_path.with_name(f"{output_path.stem}_preview.jpg")
            if preview_path.exists() and not options.overwrite:
                preview_path = build_output_path(
                    preview_path,
                    output_dir=preview_path.parent,
                    suffix="",
                    extension=".jpg",
                    overwrite=False,
                )
            preview = make_side_by_side_preview(
                image,
                cutout,
                background_color=options.preview_background,
            )
            preview.save(preview_path, format="JPEG", quality=92)

        return ProcessingResult(
            input_path=source,
            output_path=output_path,
            alpha_mask_path=alpha_path,
            preview_path=preview_path,
            width=image.width,
            height=image.height,
            duration_seconds=perf_counter() - started,
        )

    @staticmethod
    def _open_image(path: Path) -> Image.Image:
        with Image.open(path) as image:
            return ImageOps.exif_transpose(image).convert("RGB")
