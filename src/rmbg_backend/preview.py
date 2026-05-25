from __future__ import annotations

from PIL import Image, ImageColor, ImageDraw


def flatten_on_color(image: Image.Image, color: str) -> Image.Image:
    rgba = image.convert("RGBA")
    background = Image.new("RGBA", rgba.size, ImageColor.getrgb(color)[:3] + (255,))
    background.alpha_composite(rgba)
    return background.convert("RGB")


def composite_on_checkerboard(
    image: Image.Image,
    *,
    square_size: int = 24,
    light: str = "#ffffff",
    dark: str = "#e5e5ea",
) -> Image.Image:
    rgba = image.convert("RGBA")
    board = _checkerboard(rgba.size, square_size=square_size, light=light, dark=dark)
    board.alpha_composite(rgba)
    return board.convert("RGB")


def make_side_by_side_preview(
    original: Image.Image,
    cutout: Image.Image,
    *,
    background_color: str = "#f2f2f7",
    max_side: int = 1600,
) -> Image.Image:
    before = original.convert("RGB")
    after = composite_on_checkerboard(cutout)

    before.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
    after.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)

    width = before.width + after.width
    height = max(before.height, after.height)
    canvas = Image.new("RGB", (width, height), ImageColor.getrgb(background_color)[:3])
    canvas.paste(before, (0, (height - before.height) // 2))
    canvas.paste(after, (before.width, (height - after.height) // 2))
    return canvas


def _checkerboard(size: tuple[int, int], *, square_size: int, light: str, dark: str) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, ImageColor.getrgb(light)[:3] + (255,))
    draw = ImageDraw.Draw(image)
    dark_rgba = ImageColor.getrgb(dark)[:3] + (255,)

    for y in range(0, height, square_size):
        for x in range(0, width, square_size):
            if (x // square_size + y // square_size) % 2:
                draw.rectangle((x, y, x + square_size - 1, y + square_size - 1), fill=dark_rgba)

    return image
