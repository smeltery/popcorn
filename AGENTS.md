# Agent Instructions for popcorn

popcorn is a smeltery monorepo for terminal session recording,
playback, streaming, and hosting tools.

## Project Layout

- `crates/cli`: Rust CLI package. Produces the `popcorn` binary and `.pop`
  recording files.
- `docs`: repository-level architecture, development, operations, and security
  documentation.

Future packages should stay inside the monorepo rather than becoming separate
repositories unless there is a strong release or ownership reason.

## Task Completion Requirements

- Run the smallest relevant checks during iteration.
- Before considering broad porting or branding work complete, run:
  - `cargo fmt --all --check`
  - `cargo clippy --workspace --all-targets --locked`
  - `cargo test --workspace --locked`
  - `crates/cli/tests/integration.sh`
- Do not mark the port complete while user-facing `asciinema` branding remains
  outside deliberate compatibility references.

## Branding Rules

- Product and CLI name: `popcorn`.
- Recording file extension: `.pop`.
- User-facing recording format name: `popcast`.
- Environment variables use `POPCORN_`.
- Config/state paths use `popcorn`.
- Canonical brand assets, fonts, and color tokens live in `assets/brand`.
- Run `python3 scripts/sync_brand.py` after changing canonical assets; use
  `--player` after rebuilding the player to update docs and CLI bundles together.

Internal compatibility code may still read historical asciinema/asciicast
payloads when that preserves interoperability, but new user-facing examples and
outputs should use Popcorn names.
