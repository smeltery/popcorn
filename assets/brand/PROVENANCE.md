# Brand provenance

## Supplied artwork

The user supplied `popcorn-brand-kit-v1.zip` and `BRAND_GUIDELINES.md` on
2026-10-29 for integration into smeltery/popcorn. `source/` preserves the kit
unchanged. Its guidelines describe a concept identity; the production decisions
and usage rules are recorded in [README.md](README.md).

The supplied files contain no artwork license or author grant. They are used
here at the project owner's request; no separate public redistribution or
trademark license is asserted by this document. Component code licenses do not
automatically establish the licensing of these supplied images.

The production mascot was edited with the built-in image generation tool to
replace the laptop's Octocat emblem with a plain play symbol. The original
third-party emblem remains only in the archived concept reference. The selected
edit preserves the source character and pose. Prompt:

> Change only the GitHub/Octocat emblem on the silver laptop lid to a simple
> dark rounded right-pointing play triangle, matching the laptop perspective.
> Preserve the mascot face, popcorn, red-white tub, laptop, textures, lighting,
> colors, proportions and floating decorative popcorn/rays. Keep the whole
> illustration uncropped with at least 10% transparent clear space on every side.
> Genuine transparent background, no text, no other logos.

Clear space is supplied by presentation layout; the raster itself is tightly
cropped. An additional cleanup edit was evaluated but not selected.

The simplified SVG marks are new project artwork following the supplied
face/tub concept. The original Plus Jakarta Sans wordmark was replaced following
the user’s request to match the concept board more closely. The new wordmark
and red app tile are raster artwork recreated with the built-in image tool.
`scripts/export_brand.py` preserves those masters and produces the combined
logo, export sizes, and social card. The monochrome mark is an editable SVG.

## Reference-matching revision

The user supplied the full board and cropped logo/icon references, now in
`source/references/`. The selected generation prompts requested:

- App icon: recreate only the red rounded-square app icon, matching its glossy
  shading, asymmetrical butter-yellow head, dark eyes with white glints, open
  red smile, and scalloped red-white tub. No laptop, decorations, or text;
  transparent outer margin and rounded corners.
- Wordmark: exact lowercase `popcorn`, tightly packed inflated cream bubble
  letters, small circular counters, thick cinema-red edging, darker lower
  extrusion, and two gold rays above the final `n`. Match the middle wordmark
  panel; transparent background and no mascot or labels.

Generated combined-logo candidates added an unwanted background glow and were
rejected. The production full logo is composed from the existing transparent
mascot and the selected wordmark through an SVG layout, then exported as PNG.
These are close visual recreations, not original vector sources from the board.

## Fonts

- Plus Jakarta Sans: downloaded from
  [google/fonts](https://github.com/google/fonts/tree/main/ofl/plusjakartasans),
  upstream [Tokotype](https://github.com/tokotype/PlusJakartaSans), on 2026-10-29.
  The full variable TTF is retained, and WOFF2 is converted without subsetting.
  See `fonts/PlusJakartaSans-OFL.txt`.
- JetBrains Mono: existing repository WOFF2 files, copied without alteration.
  The license is from the [upstream project](https://github.com/JetBrains/JetBrainsMono/blob/master/OFL.txt).
  See `fonts/JetBrainsMono-OFL.txt`.

Both font license notices accompany the distributed webfont copies.
Existing upstream software attribution remains in the component licenses.

## Homepage and banner revision

`mascot-bust.png` and `popcorn-kernel.png` were recreated with the built-in
image tool using the approved board as reference. The bust prompt requested
the icon character without its red tile, laptop, wordmark, rays or background:
asymmetrical ivory head, glossy brown eyes, open red smile, striped scalloped
tub and transparent margins. The kernel prompt requested a single four-lobed
ivory/butter-gold popcorn piece with soft 3D shading, no face, glow or shadow,
and a transparent background. These are visual recreations, not extracted
original artwork. Existing approved mascot, wordmark and app-icon masters
remain unchanged.

Gold rays are native SVG. Horizontal lockups and both social layouts are
reproducible SVG compositions exported by `scripts/export_brand.py`. Social
commands and supporting text use outlines from JetBrains Mono; the headline
uses Plus Jakarta Sans. Light/dark usage exports intentionally include their
surface backgrounds; `horizontal-logo.png` is the transparent production asset.
The homepage demo is a short authored popcast fixture, not a captured user
session.
