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


def lettering(text: str, weight: int = 800) -> tuple[str, int]:
    font = instantiateVariableFont(TTFont(BRAND / "fonts/PlusJakartaSans.ttf"), {"wght": weight})
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


def text_svg(text: str, x: int, y: int, size: int, color: str, weight: int = 800) -> str:
    paths, _ = lettering(text, weight)
    return f'<g transform="translate({x} {y}) scale({size / 1000} {-size / 1000})" fill="{color}">{paths}</g>'


def main() -> None:
    font = TTFont(BRAND / "fonts/PlusJakartaSans.ttf", recalcTimestamp=False)
    font.flavor = "woff2"
    font.save(BRAND / "fonts/PlusJakartaSans.woff2")
    paths, width = lettering("popcorn")
    (IMAGES / "wordmark.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="-120 -120 {width + 240} 1060">'
        '<g transform="translate(0 700) scale(1 -1)" fill="#FFF4D6" stroke="#B91C35" '
        f'stroke-width="65" stroke-linejoin="round" paint-order="stroke">{paths}</g></svg>\n'
    )
    for size, name in ((16, "favicon-16.png"), (32, "favicon-32.png"),
                       (64, "favicon.png"), (180, "apple-touch-icon.png"), (512, "avatar.png")):
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size),
                        str(IMAGES / "icon.svg"), "-o", str(IMAGES / name)], check=True)
    social = (
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        'width="1280" height="640" viewBox="0 0 1280 640">'
        '<rect width="1280" height="640" fill="#15151B"/>'
        '<rect x="64" y="68" width="64" height="8" rx="4" fill="#FFCC4D"/>'
        f'<image x="60" y="115" width="600" height="155" xlink:href="{image_data("wordmark.svg")}"/>'
        + text_svg("Make your terminal", 72, 325, 40, "#FFF4D6")
        + text_svg("sessions pop.", 72, 380, 40, "#FFF4D6")
        + text_svg("Record, replay, and share.", 72, 440, 26, "#A6A6B3", 500)
        + '<rect x="72" y="475" width="480" height="65" rx="12" fill="#23232D"/>'
        + text_svg("$ popcorn rec demo.pop", 95, 517, 25, "#FFCC4D", 600)
        + f'<image x="710" y="70" width="500" height="500" xlink:href="{image_data("mascot.png")}"/>'
        + '</svg>'
    )
    with tempfile.TemporaryDirectory(prefix="popcorn-brand-") as temp:
        source = Path(temp) / "social.svg"
        source.write_text(social)
        subprocess.run(["rsvg-convert", str(source), "-o", str(IMAGES / "social-preview.png")], check=True)
    checksums = {
        str(path.relative_to(BRAND)): hashlib.sha256(path.read_bytes()).hexdigest()
        for directory in ("source", "fonts", "images")
        for path in sorted((BRAND / directory).iterdir())
        if path.is_file()
    }
    (BRAND / "checksums.json").write_text(json.dumps(checksums, indent=2) + "\n")


if __name__ == "__main__":
    main()
