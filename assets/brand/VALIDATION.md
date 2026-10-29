# Brand integration validation

## Reference-matching revision

The revised logo family follows the supplied board: shaded red app tile,
cream bubble wordmark with red extrusion and gold rays, composed full logo,
and outlined monochrome mark. Review all four in [preview.html](preview.html).

The revision passed `cargo fmt --all --check`, workspace Clippy with warnings
denied, all 315 workspace Rust tests, all 66 CLI integration checks,
`make check` (including strict docs build), and `mix assets.build`.
Recording SVG and admin controller tests passed: 23 tests.
Brand synchronization and all 26 current source/font/export hashes were checked.
The previously recorded 195-player-test result applies to the unchanged player
code; this revision changes image assets and their references.

Full-color icon and wordmark masters are PNGs. The full logo is composed from
transparent masters; rejected generated variants with background glow are not
distributed. Tiny favicons and recording SVG previews use the revised vector
icon. This is a close recreation of the supplied concept, not a claim of
pixel-exact reproduction or recovered original vector artwork.

## Initial integration record

Reviewed locally on 2026-10-29. Changes are grouped into canonical assets and
standards, README/docs, and server/player integration.

## Automated checks

| Check | Result |
| --- | --- |
| `cargo fmt --all --check` | Passed |
| `mbx clippy --workspace --all-targets --locked -- -D warnings` | Passed |
| `mbx test --workspace --locked` | 315 tests passed |
| `crates/cli/tests/integration.sh` | 66 checks passed |
| `make check` | Passed, including strict docs build and brand sync |
| Player `bun run build` | Passed |
| Player `bun run test --workers=4` | 195 tests passed across Chromium, Firefox, driver, and unit projects |
| Server `mix assets.build` | Passed |
| Affected server `mix test` | 24 tests passed |
| `python3 scripts/sync_brand.py --player --check` | All distributed copies current |
| `checksums.json` | All 22 source, font, and export hashes verified |
| `git diff --check` | Passed |

Rust compiling checks used the repository's `mbx` wrapper. The affected server
tests cover recording SVG output, the public explore controller, admin
dashboard, and layout view. Existing server/compiler warnings remain outside
this branding change.

The local macOS Firefox build initially failed before opening any page because
it attempted to use the normal Firefox app-data directory. The successful full
player run used `CFFIXED_USER_HOME=/tmp/popcorn-firefox-home` with a new empty
directory. No user profile or OS permissions were changed. This matches the
[upstream Playwright report](https://github.com/microsoft/playwright/issues/42768).
The repository's browser dependency and CI configuration remain unchanged.

## Rendered review

- Reviewed docs at 1440px and 390px, including the real light/dark toggle.
  Images and locally hosted fonts load; no horizontal page overflow.
- Reviewed public server navigation and About page at desktop/mobile widths.
  The mobile menu opens, images load, and the console reports no page errors.
- Reviewed admin dashboard in light/dark mode and at 390px. Mobile navigation
  wraps above the content; tables scroll within their own containers.
- Reviewed the simplified icon at 16px, 32px, and 64px on cream and midnight,
  and the monochrome mark in both foreground colors.
- Reviewed mascot transparency on light/dark surfaces and the 1280 × 640 social
  preview. Full mascot artwork is reserved for larger surfaces.
- Checked visible keyboard focus in docs, public navigation, and player
  controls. Player controls use a gold 2px outline; public header links use 3px.
- Opened an actual CLI-served live session. Its favicon returns `200 image/png`,
  its title identifies Popcorn, and controls use Midnight while the terminal
  retains its own `#121314` background. Mobile playback has no page overflow.
- Opened the docs player using the refreshed bundled JavaScript and CSS; the
  start overlay uses the new play symbol. Existing player rendering tests
  continue to cover embedded/explicit terminal themes and palettes.

## Contrast measurements

Ratios computed from the canonical sRGB colors:

| Pair | Ratio |
| --- | --- |
| Midnight text / paper | 17.74:1 |
| Action red links / paper | 6.25:1 |
| White labels / action red buttons | 6.40:1 |
| Muted text / paper | 5.86:1 |
| Cream text / Midnight | 16.59:1 |
| Light red links / Midnight | 8.19:1 |
| Silver labels / Midnight | 7.56:1 |
| Gold playback cues / Midnight | 12.12:1 |

These measurements cover the new brand combinations, not a claim that every
pre-existing screen has undergone a complete accessibility audit.

## Branding audit

Production logos, navigation, favicons, start overlays, and recording SVG
previews use the new identity. Remaining upstream names in the examined source
are deliberate parser/CLI/WebSocket compatibility aliases and attribution.
Historical recordings and archived source concepts remain unchanged. The source
mascot's Octocat emblem is absent from the selected production mascot.

The social preview is provided as a repository asset and as default server
metadata. Updating GitHub's repository social-preview setting is a separate
publishing action and was not performed.
