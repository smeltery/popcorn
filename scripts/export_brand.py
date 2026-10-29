#!/usr/bin/env python3
"""Export vector typography and raster icons (fontTools, brotli, rsvg-convert)."""

from __future__ import annotations

import base64
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

BRAND = Path(__file__).resolve().parents[1] / "assets/brand"
IMAGES = BRAND / "images"


def lettering(text: str, weight: int = 800, mono: bool = False) -> tuple[str, int]:
    font = (TTFont(BRAND / "fonts/JetBrainsMono-Regular.woff2") if mono else
            instantiateVariableFont(TTFont(BRAND / "fonts/PlusJakartaSans.ttf"), {"wght": weight}))
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    x = 0
    paths = []
    for char in text:
        name = cmap[ord(char)]
        pen = SVGPathPen(glyphs)
        glyphs[name].draw(pen)
        paths.append(f'<path transform="translate({x} 0)" d="{pen.getCommands()}"/>')
        x += glyphs[name].width
    return "".join(paths), x


def image_data(name: str) -> str:
    path = IMAGES / name
    mime = "image/png" if path.suffix == ".png" else "image/svg+xml"
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode()


def text_svg(text: str, x: int, y: int, size: int, color: str, weight: int = 800, mono: bool = False) -> str:
    paths, _ = lettering(text, weight, mono)
    return f'<g transform="translate({x} {y}) scale({size / 1000} {-size / 1000})" fill="{color}">{paths}</g>'


def raster_export(svg: str, name: str) -> None:
    with tempfile.TemporaryDirectory(prefix="popcorn-brand-") as temp:
        source = Path(temp) / "layout.svg"
        source.write_text(svg)
        subprocess.run(["rsvg-convert", str(source), "-o", str(IMAGES / name)], check=True)


def main() -> None:
    font = TTFont(BRAND / "fonts/PlusJakartaSans.ttf", recalcTimestamp=False)
    font.flavor = "woff2"
    font.save(BRAND / "fonts/PlusJakartaSans.woff2")
    for size, name in ((16, "favicon-16.png"), (32, "favicon-32.png"),
                       (64, "favicon.png"), (180, "apple-touch-icon.png"), (512, "avatar.png")):
        if size <= 32:
            source = IMAGES / "icon.svg"
            subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size),
                            str(source), "-o", str(IMAGES / name)], check=True)
        else:
            raster_export(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
                f'width="{size}" height="{size}"><image width="{size}" height="{size}" '
                f'xlink:href="{image_data("app-icon.png")}"/></svg>', name
            )
    # This is an SVG layout of raster masters, not a vector tracing of the artwork.
    lockup = (
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'width="1200" height="850" viewBox="0 0 1200 850">'
        '<defs><clipPath id="mascot-crop"><rect width="1200" height="625"/></clipPath></defs>'
        f'<image x="110" y="10" width="980" height="896" clip-path="url(#mascot-crop)" '
        f'xlink:href="{image_data("mascot.png")}"/>'
        f'<image x="0" y="470" width="1200" height="400" xlink:href="{image_data("wordmark.png")}"/>'
        '</svg>'
    )
    raster_export(lockup, "full-logo.png")
    horizontal = (
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'width="800" height="200">'
        f'<image x="0" y="0" width="200" height="200" xlink:href="{image_data("mascot-bust.png")}"/>'
        f'<image x="190" y="0" width="600" height="200" xlink:href="{image_data("wordmark.png")}"/>'
        '</svg>'
    )
    raster_export(horizontal, "horizontal-logo.png")
    for surface, color in (("light", "#FFFCF5"), ("dark", "#15151B")):
        raster_export(horizontal.replace('<image', f'<rect width="800" height="200" fill="{color}"/><image', 1),
                      f"horizontal-logo-{surface}.png")
    for name, height in (("social-banner.png", 400), ("social-preview.png", 640)):
        offset = (height - 400) // 2
        social = (
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
            f'width="1280" height="{height}">'
            '<defs><radialGradient id="glow"><stop stop-color="#574031"/>'
            '<stop offset="1" stop-color="#15151B"/></radialGradient></defs>'
            f'<rect width="1280" height="{height}" fill="url(#glow)"/>'
            f'<g transform="translate(0 {offset})">'
            f'<image x="-65" y="-40" width="510" height="510" xlink:href="{image_data("mascot.png")}"/>'
            f'<image x="420" y="70" width="520" height="173" xlink:href="{image_data("wordmark.png")}"/>'
            + text_svg("Make your terminal sessions", 455, 270, 23, "#FFF4D6")
            + text_svg("pop.", 630, 310, 30, "#FFCC4D")
            + text_svg("Record, replay,", 960, 142, 17, "#FFF4D6", mono=True)
            + text_svg("stream, host", 960, 172, 17, "#FFF4D6", mono=True)
            + text_svg("and render", 960, 202, 17, "#FFF4D6", mono=True)
            + text_svg(".pop files.", 960, 232, 17, "#FFCC4D", mono=True)
            + text_svg("$ popcorn rec demo.pop", 490, 362, 19, "#FFF4D6", mono=True)
            + f'<image x="1170" y="-25" width="130" height="130" xlink:href="{image_data("popcorn-kernel.png")}"/>'
            + f'<image x="1110" y="290" width="170" height="170" xlink:href="{image_data("popcorn-kernel.png")}"/>'
            + f'<image x="390" y="-55" width="110" height="110" xlink:href="{image_data("popcorn-kernel.png")}"/>'
            + '</g></svg>'
        )
        raster_export(social, name)
    checksums = {
        str(path.relative_to(BRAND)): hashlib.sha256(path.read_bytes()).hexdigest()
        for directory in ("source", "fonts", "images")
        for path in sorted((BRAND / directory).rglob("*"))
        if path.is_file()
    }
    (BRAND / "checksums.json").write_text(json.dumps(checksums, indent=2) + "\n")


if __name__ == "__main__":
    main()
