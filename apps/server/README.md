# Popcorn server

[![CI](https://github.com/smeltery/popcorn/actions/workflows/ci.yml/badge.svg)](https://github.com/smeltery/popcorn/actions/workflows/ci.yml)
[![Release](https://github.com/smeltery/popcorn/actions/workflows/release.yml/badge.svg)](https://github.com/smeltery/popcorn/actions/workflows/release.yml)
[![Latest Release](https://img.shields.io/github/v/release/smeltery/popcorn?sort=semver)](https://github.com/smeltery/popcorn/releases/latest)
[![Elixir](https://img.shields.io/badge/elixir-1.19%2B-purple)](mix.exs)
[![License](https://img.shields.io/badge/license-Apache-2.0-blue)](../../LICENSE)

Popcorn server is the server-side component of the Popcorn ecosystem.

It implements a hosting platform for terminal session recordings and live
streaming. It offers a familiar web interface for viewing, browsing, sharing
and managing recordings and streams. This includes an HTTP API used by the
[Popcorn CLI](../../crates/cli).

The server is built with [Elixir language](https://elixir-lang.org/) and
[Phoenix framework](https://www.phoenixframework.org/). It embeds popcorn's
virtual terminal, [avt](https://github.com/smeltery/popcorn/tree/main/crates/avt), which is utilized by
tasks such as preview generation, recording analysis and live stream state
bookkeeping.

Popcorn is self-hosted by default. Point the CLI at your own server with
`POPCORN_SERVER_URL=https://popcorn.example.com` and upload recordings to the
instance you control.

Notable features:

- hosting of terminal session recordings in
  [popcast](../../apps/docs/docs/manual/popcast/v3.md) format,
- live streaming of terminal sessions,
- integrated [Popcorn player](../../packages/player) for browser playback,
- full-text search using recording titles, descriptions, and _full terminal
  session content_,
- easy [sharing](https://docs.popcorn.example.com/manual/server/sharing/) of
  recordings via secret links,
- easy [embedding](https://docs.popcorn.example.com/manual/server/embedding/) of the
  player, or linking via preview images (SVG),
- privacy friendly - no tracking, no ads,
- visibility control for recordings and streams: private, unlisted, or public,
- editable recording/stream metadata like title or long description (Markdown),
- configurable terminal themes and font families,
- download of plain text transcripts (`.txt`) of a recordings.

Refer to the [Popcorn server docs](../docs/docs/manual/server/index.md) for
further details.

## License

Popcorn server is licensed under the Apache-2.0. See
[LICENSE](./LICENSE) for details.

Derived from [asciinema-server](https://github.com/asciinema/asciinema-server).
Copyright Marcin Kulik and contributors. Popcorn modifications copyright
2026 smeltery, distributed under the same license.
