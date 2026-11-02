"""Draws the Kasumi app icon and README logo from the same geometry as `KasumiMark` in Shared/Brand.swift.

The mark is a sun with two bands of mist passing in front of it, after the
suyari-gasumi bands in Japanese screen painting. Bands are separated from the
sun by a thin gap, so the mark stays one flat colour.

Usage: python scripts/make_icon.py
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ACCENT = (0xF2, 0xA6, 0x5A, 255)
BACKGROUND = (0x14, 0x14, 0x15, 255)
SUPERSAMPLE = 4

# Geometry in a unit square (0..1), mirrored in KasumiMark.
SUN = (0.48, 0.46, 0.24)  # centre x, centre y, radius
BANDS = [  # left x, right x, centre y
    (0.10, 0.76, 0.62),
    (0.28, 0.90, 0.74),
]
BAND_HEIGHT = 0.08
GAP = 0.03


def mark_mask(canvas):
    """Single-channel mask of the mark drawn into a canvas x canvas square."""
    def pill(draw, left, right, cy, height):
        draw.rounded_rectangle(
            (left * canvas, (cy - height / 2) * canvas, right * canvas, (cy + height / 2) * canvas),
            radius=height / 2 * canvas,
            fill=255,
        )

    sun = Image.new("L", (canvas, canvas), 0)
    cx, cy, r = SUN
    ImageDraw.Draw(sun).ellipse(((cx - r) * canvas, (cy - r) * canvas, (cx + r) * canvas, (cy + r) * canvas), fill=255)

    cutouts = Image.new("L", (canvas, canvas), 0)
    bands = Image.new("L", (canvas, canvas), 0)
    for left, right, band_cy in BANDS:
        pill(ImageDraw.Draw(cutouts), left - GAP, right + GAP, band_cy, BAND_HEIGHT + GAP * 2)
        pill(ImageDraw.Draw(bands), left, right, band_cy, BAND_HEIGHT)

    return ImageChops.lighter(ImageChops.subtract(sun, cutouts), bands)


def draw_icon(size, scale, background):
    """Mark scaled by `scale` around the centre of a size x size image."""
    canvas = size * SUPERSAMPLE
    inner = int(canvas * scale)
    mask = Image.new("L", (canvas, canvas), 0)
    mask.paste(mark_mask(inner), ((canvas - inner) // 2, (canvas - inner) // 2))

    image = Image.new("RGBA", (canvas, canvas), background)
    image.paste(Image.new("RGBA", (canvas, canvas), ACCENT), mask=mask)
    return image.resize((size, size), Image.LANCZOS)


def main():
    icon_dir = ROOT / "Kasumi/Resources/Assets.xcassets/AppIcon.appiconset"
    icon_dir.mkdir(parents=True, exist_ok=True)
    draw_icon(1024, 0.88, BACKGROUND).convert("RGB").save(icon_dir / "AppIcon.png")

    docs = ROOT / "docs"
    docs.mkdir(exist_ok=True)
    draw_icon(256, 0.88, BACKGROUND).save(docs / "icon.png")
    print("icons written")


if __name__ == "__main__":
    main()
