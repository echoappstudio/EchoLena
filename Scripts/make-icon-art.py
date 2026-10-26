#!/usr/bin/env python3
"""Draws EchoLena's icon art: a silver clipboard with three black lines on a black tile (Signature).
Needs Pillow; not run in CI.

Writes these files from one geometry:
- Resources/AppIcon.icon/Assets/clipboard.png: the transparent glyph layer for Icon Composer
  (macOS draws the rounded square, shadow and glass; the gradient is the .icon's own fill, which
  must match BUILT_IN's tile gradient below).
- Resources/AppIcon-1024.png: the flat icon (the .icns fallback) on the macOS grid.
- docs/images/echolena-icon.png: the same flat icon, for the README.
- Resources/SkinIcons/icon-<skin>.png: the flat icon in each other skin's colours, which the app
  puts on itself in Finder when that skin is chosen (Signature, the default, is the app's own icon).
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SS = 2  # draw at 2x, then reduce, for smooth edges
SIZE = 1024

# Each skin's icon: tile top and bottom, clipboard top and bottom, and the line colour.
# Signature is Echo App Studio's black and silver; the others are lit from above around the skin's
# accent (ShelfSkin.palette).
SKINS = {
    "signature": ((0x22, 0x23, 0x26), (0x05, 0x06, 0x07), (0xF6, 0xF6, 0xF8), (0x8C, 0x8D, 0x93), (0x0B, 0x0C, 0x0D)),
    "sky": ((0x3F, 0x92, 0xF2), (0x0B, 0x3F, 0x8F), (0xFF, 0xFF, 0xFF), (0xCF, 0xE0, 0xFA), (0x0E, 0x4A, 0xA6)),
    "green": ((0x37, 0xC6, 0x79), (0x0B, 0x5C, 0x35), (0xFF, 0xFF, 0xFF), (0xD2, 0xF3, 0xE0), (0x0E, 0x6B, 0x3E)),
    "turquoise": ((0x3C, 0xC2, 0xB8), (0x0D, 0x5A, 0x55), (0xFF, 0xFF, 0xFF), (0xD1, 0xF2, 0xEF), (0x0F, 0x6C, 0x66)),
    "bordeaux": ((0xCB, 0x4C, 0x63), (0x5A, 0x12, 0x23), (0xFF, 0xFF, 0xFF), (0xF6, 0xD3, 0xD9), (0x7A, 0x1C, 0x31)),
    "wisteria": ((0x95, 0x80, 0xE6), (0x3B, 0x2D, 0x82), (0xFF, 0xFF, 0xFF), (0xE4, 0xDC, 0xFA), (0x4B, 0x3A, 0x9B)),
}
BUILT_IN = "signature"  # the app's own icon: ShelfSkin.builtInIcon
SHIFT = 14  # centres the glyph's visual weight on the canvas


def s(value: float) -> int:
    return round(value * SS)


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    strip = Image.new("RGB", (1, height))
    for y in range(height):
        t = y / max(1, height - 1)
        strip.putpixel((0, y), tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return strip.resize(size)


def glyph(shape_top: tuple[int, int, int], shape_bottom: tuple[int, int, int], lines: tuple[int, int, int]) -> Image.Image:
    """The clipboard (board and clip) in a vertical gradient, with its slot and three lines, on a transparent canvas."""
    full = (s(SIZE), s(SIZE))
    mask = Image.new("L", full, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((s(292), s(240 + SHIFT), s(732), s(800 + SHIFT)), radius=s(76), fill=255)
    mask_draw.rounded_rectangle((s(412), s(196 + SHIFT), s(612), s(306 + SHIFT)), radius=s(46), fill=255)
    top, bottom = 196 + SHIFT, 800 + SHIFT
    # The gradient runs over the clipboard's own height, not the whole canvas.
    band = vertical_gradient((full[0], s(bottom - top)), shape_top, shape_bottom)
    fill = Image.new("RGB", full, shape_bottom)
    fill.paste(shape_top, (0, 0, full[0], s(top)))
    fill.paste(band, (0, s(top)))
    canvas = Image.new("RGBA", full, (0, 0, 0, 0))
    canvas.paste(fill.convert("RGBA"), (0, 0), mask)
    draw = ImageDraw.Draw(canvas)
    line = (*lines, 255)
    draw.rounded_rectangle((s(452), s(226 + SHIFT), s(572), s(266 + SHIFT)), radius=s(20), fill=line)
    for y, right in ((430, 652), (530, 652), (630, 552)):
        draw.rounded_rectangle((s(372), s(y + SHIFT), s(right), s(y + 44 + SHIFT)), radius=s(22), fill=line)
    return canvas


def flat_icon(art: Image.Image, top: tuple[int, int, int], bottom: tuple[int, int, int], sheen_strength: int) -> Image.Image:
    """The macOS-grid icon: an 824-point body with a 185-point radius, soft shadow, gradient and sheen."""
    full = (s(SIZE), s(SIZE))
    body_box = (s(100), s(100), s(924), s(924))
    body_mask = Image.new("L", full, 0)
    ImageDraw.Draw(body_mask).rounded_rectangle(body_box, radius=s(185), fill=255)

    shadow = Image.new("RGBA", full, (0, 0, 0, 0))
    shadow.putalpha(body_mask.filter(ImageFilter.GaussianBlur(s(22))).point(lambda v: int(v * 0.30)))
    shadow = ImageChops.offset(shadow, 0, s(14))

    body = vertical_gradient(full, top, bottom).convert("RGBA")
    sheen = Image.new("RGBA", full, (255, 255, 255, 0))
    sheen_alpha = Image.new("L", full, 0)
    sheen_draw = ImageDraw.Draw(sheen_alpha)
    for y in range(s(100), s(520)):
        t = (y - s(100)) / (s(520) - s(100))
        sheen_draw.line((0, y, full[0], y), fill=round(sheen_strength * (1 - t)))
    sheen.putalpha(ImageChops.multiply(sheen_alpha, body_mask))
    body = Image.alpha_composite(body, sheen)

    art_shadow = Image.new("RGBA", full, (0, 0, 0, 0))
    art_shadow.putalpha(art.getchannel("A").filter(ImageFilter.GaussianBlur(s(14))).point(lambda v: int(v * 0.30)))
    art_shadow = ImageChops.offset(art_shadow, 0, s(10))

    icon = Image.new("RGBA", full, (0, 0, 0, 0))
    icon = Image.alpha_composite(icon, shadow)
    body_layer = Image.new("RGBA", full, (0, 0, 0, 0))
    body_layer.paste(body, (0, 0), body_mask)
    # A faint rim, like the other Signature icons.
    rim = Image.new("RGBA", full, (0, 0, 0, 0))
    ImageDraw.Draw(rim).rounded_rectangle(
        (s(101.5), s(101.5), s(922.5), s(922.5)), radius=s(184), outline=(255, 255, 255, 30 if top[0] < 0x40 else 0), width=s(3)
    )
    body_layer = Image.alpha_composite(body_layer, rim)
    icon = Image.alpha_composite(icon, body_layer)
    icon = Image.alpha_composite(icon, art_shadow)
    icon = Image.alpha_composite(icon, art)
    return icon.resize((SIZE, SIZE), Image.LANCZOS)


def skin_icon(name: str) -> Image.Image:
    tile_top, tile_bottom, shape_top, shape_bottom, lines = SKINS[name]
    return flat_icon(glyph(shape_top, shape_bottom, lines), tile_top, tile_bottom, 26 if name == BUILT_IN else 60)


def main() -> None:
    tile_top, tile_bottom, shape_top, shape_bottom, lines = SKINS[BUILT_IN]
    art = glyph(shape_top, shape_bottom, lines)
    layer = art.resize((SIZE, SIZE), Image.LANCZOS)
    layer_path = ROOT / "Resources/AppIcon.icon/Assets/clipboard.png"
    layer.save(layer_path)
    flat = skin_icon(BUILT_IN)
    flat.save(ROOT / "Resources/AppIcon-1024.png")
    flat.save(ROOT / "docs/images/echolena-icon.png")
    skin_dir = ROOT / "Resources/SkinIcons"
    skin_dir.mkdir(exist_ok=True)
    for stale in skin_dir.glob("icon-*.png"):
        stale.unlink()
    for name in SKINS:
        if name == BUILT_IN:
            continue
        skin_icon(name).save(skin_dir / f"icon-{name}.png", optimize=True)
    print("Wrote", layer_path, "the flat icons and the skin icons.")
    print("Icon Composer fill (top, bottom):", ["srgb:%.5f,%.5f,%.5f,1.00000" % tuple(c / 255 for c in col) for col in (tile_top, tile_bottom)])


if __name__ == "__main__":
    main()
