# Popcorn Player Virtual Terminal

[![Release](https://github.com/dotbrains/popcorn/actions/workflows/release.yml/badge.svg)](https://github.com/dotbrains/popcorn/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/dotbrains/popcorn?sort=semver)](https://github.com/dotbrains/popcorn/releases/latest)
[![Rust](https://img.shields.io/badge/rust-1.85%2B-orange)](Cargo.toml)
[![License](https://img.shields.io/badge/license-PolyForm%20Shield%201.0.0-blue)](../../LICENSE)

This package builds the WebAssembly virtual terminal used by the browser
player. It wraps the Rust terminal engine and exposes a compact rendering model
for JavaScript UI code.

## Responsibilities

- Parse terminal output through the Rust terminal engine.
- Serialize terminal lines, text spans, background spans, and glyph metadata for
  the browser renderer.
- Keep terminal behavior shared between native Rust tooling and the web player.

## Development

Build and test this package from the repository root through the Flox
environment:

```sh
flox activate -- cargo test --manifest-path packages/player/src/vt/Cargo.toml
```

The generated WebAssembly output is consumed by the player package. Keep the
Rust data structures in sync with the JavaScript terminal renderer whenever the
serialized shape changes.
