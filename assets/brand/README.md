# Popcorn brand

Make your terminal sessions pop.

Popcorn helps you record, replay, stream, host, share, and render terminal
sessions. The recording format is **popcast**; its file extension is **`.pop`**.
Use “Record, replay, and share terminal sessions.” as the short description.

## Assets

- `images/mascot.png`: full-color mascot for README and landing-page artwork.
- `images/icon.svg`: simplified face/tub mark for navigation and small icons.
- `images/wordmark.svg`: lowercase outlined lettering; no installed font required.
- `images/monochrome.svg`: single-color mark using `currentColor` when inline.
- `images/avatar.png`: square 512px avatar.
- `images/favicon*.png`: 16px, 32px, and 64px icons.
- `images/apple-touch-icon.png`: 180px icon.
- `images/social-preview.png`: 1280 × 640 repository/social preview.
- `source/`: unchanged supplied concepts and proposed guidelines, for reference.

Leave at least 10% clear space around the mascot. Preserve its proportions,
colors, and face. Use the simplified mark below 64px; omit floating decorations
in small icons. Use transparent artwork on plain backgrounds with good contrast.
The source brand board is a visual reference, not a sheet of production logos.

## Colors and typography

`tokens.css` is the canonical palette. Cinema Red (`#F43F4F`), Butter Gold
(`#FFCC4D`), Cream (`#FFF4D6`), Midnight (`#15151B`), and Silver (`#A6A6B3`)
define the identity. Darker red action/link variants support light interfaces;
light red links and gold playback cues support dark interfaces. Keep success,
warning, error, and live states distinct and pair them with text or icons.

Use locally hosted Plus Jakarta Sans for UI and headings, and JetBrains Mono
for commands and metadata. Font loading uses `swap` and system fallbacks.
Recording-supplied terminal palettes and user-selected terminal fonts remain
independent of interface branding.

## Updating assets

Edit canonical files here, then run:

```sh
python3 scripts/sync_brand.py
python3 scripts/sync_brand.py --check
```

App copies are checked in so docs, server, and CLI builds work independently.
`make check` detects drift. After changing the browser player, build it and
refresh the docs and CLI bundles together:

```sh
(cd packages/player && bun run build)
python3 scripts/sync_brand.py --player
python3 scripts/sync_brand.py --player --check
```

To regenerate font outlines, WOFF2, icons, and the social preview, install
`assets/brand/requirements.txt` in a temporary Python environment and provide
`rsvg-convert` on PATH, then run `python scripts/export_brand.py`. This does
not regenerate the mascot. The raster master is preserved independently.
The export command also records SHA-256 hashes in `checksums.json`.

See [PROVENANCE.md](PROVENANCE.md) for source and licensing information.
See [VALIDATION.md](VALIDATION.md) for the integration review and checks.
