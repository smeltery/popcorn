# <img src="apps/docs/docs/assets/logo.png" alt="" width="32" height="32" /> Popcorn

[![CI](https://github.com/smeltery/popcorn/actions/workflows/ci.yml/badge.svg)](https://github.com/smeltery/popcorn/actions/workflows/ci.yml)
[![Release](https://github.com/smeltery/popcorn/actions/workflows/release.yml/badge.svg)](https://github.com/smeltery/popcorn/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/smeltery/popcorn?sort=semver)](https://github.com/smeltery/popcorn/releases/latest)
[![Rust](https://img.shields.io/badge/rust-1.87%2B-orange)](Cargo.toml)
[![Node](https://img.shields.io/badge/node-24%2B-green)](packages/player/package.json)
[![Elixir](https://img.shields.io/badge/elixir-1.19%2B-purple)](apps/server/mix.exs)
[![Flox](https://img.shields.io/badge/flox-integrated-blue)](.flox/env/manifest.toml)
[![License](https://img.shields.io/badge/license-PolyForm%20Shield%201.0.0-blue)](LICENSE)

Popcorn is a smeltery monorepo for terminal session recording, playback,
streaming, hosting, documentation, and rendering tools. It records terminal
sessions as lightweight `.pop` files, plays them back in a terminal or browser,
streams live sessions through a server, and renders recordings to GIFs.

All user-facing commands, package names, file extensions, release artifacts, and
docs should use Popcorn terminology.

## Notable Features

- Record terminal sessions to `.pop` files with optional keyboard input,
  selected environment metadata, markers, and idle-time limits.
- Replay recordings in a terminal with speed control, looping, stepping,
  marker-aware pauses, and optional terminal resizing.
- Stream sessions locally through the embedded web player or remotely through a
  Popcorn server, with recording and streaming available in one command.
- Convert popcast, ttyrec, stdin, local files, and HTTP(S) URLs into `.pop`,
  text, raw terminal bytes, or zstd-compressed `.zst` files.
- Concatenate multiple recordings while preserving timing and produce browser,
  server, and GIF-rendered playback experiences from the same recording format.
- Run scripted sessions in headless mode with explicit terminal dimensions and
  exit-status propagation for CI-friendly workflows.

## Status

Popcorn is early and private. The CLI, web player, server, docs site, virtual
terminal, and GIF renderer are in the monorepo. CLI release artifacts are
published on GitHub Releases. Prefer self-hosted server URLs until public hosted
infrastructure is announced.

## Quick Start

Use the checked-in Flox environment:

```bash
flox activate
mbx build -p popcorn --locked
cargo run -p popcorn -- rec demo.pop
cargo run -p popcorn -- play demo.pop
```

Without Flox, install Rust 1.87+, Bun, Node 24+, Python 3.12+,
Erlang/OTP 28.1+, Elixir, npm for server assets, and PostgreSQL tooling
directly. Compiling Cargo commands should be prefixed with
[`mbx`](https://mr-boxington.jdx.dev) (`cargo fmt` stays as `cargo`).

Build and test the main CLI:

```bash
mbx build -p popcorn --locked
mbx test --workspace --locked
crates/cli/tests/integration.sh
```

Build the browser player:

```bash
cd packages/player
bun install --frozen-lockfile
bun run build
bun run test
```

Build the docs site:

```bash
cd apps/docs
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/mkdocs build --strict
```

## Where Things Live

| Location | Role |
| --- | --- |
| `crates/cli/` | `popcorn` CLI for recording, playback, upload, conversion, and live streaming. |
| `crates/avt/` | `popcorn-terminal`, the Rust virtual terminal used by the player/server/GIF renderer. |
| `crates/agg/` | `popcorn-gif`, the GIF renderer for `.pop` recordings. |
| `packages/player/` | Browser player for `.pop` files and live streams. |
| `apps/server/` | Phoenix server for hosting recordings and live streams. |
| `apps/docs/` | MkDocs Material documentation site. |
| `docs/` | Contributor, architecture, operations, and security notes. |

## Common Tasks

```bash
cargo fmt --all --check
mbx clippy --workspace --all-targets --locked -- -D warnings
mbx test --workspace --locked
crates/cli/tests/integration.sh

make check
(cd packages/player && bun install --frozen-lockfile && bun run build && bun run test)
(cd apps/docs && .venv/bin/mkdocs build --strict)
```

Server tests require PostgreSQL. CI runs them with a PostgreSQL service:

```bash
cd apps/server
mix deps.get --locked
DATABASE_URL=ecto://postgres:postgres@localhost/popcorn_test mix test
```

## Documentation

User-facing docs live in [apps/docs/docs](apps/docs/docs). Contributor docs live
in [docs](docs):

1. [docs/README.md](docs/README.md)
1. [docs/architecture.md](docs/architecture.md)
1. [docs/development.md](docs/development.md)
1. [docs/operations.md](docs/operations.md)
1. [docs/security.md](docs/security.md)

Agent-facing repo instructions live in [AGENTS.md](AGENTS.md).

## License

PolyForm Shield License 1.0.0. See [LICENSE](LICENSE).
