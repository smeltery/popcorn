# popcorn

popcorn is a dotbrains monorepo for terminal session recording, playback,
streaming, hosting, and related tooling.

The first package is the `popcorn` CLI, a private unbranded port of the
upstream terminal recorder with `.pop` recording files and Popcorn-facing command,
configuration, and release naming.

## Packages

- `crates/cli`: Rust command-line recorder, streamer, player, and converter.

Planned ecosystem packages:

- `packages/player`: web player for `.pop` recordings and live streams.
- `apps/server`: hosting and sharing server for recordings and streams.
- `packages/terminal`: virtual terminal primitives used by the player/server.
- `apps/docs`: documentation site.

## Development

Build the CLI from the workspace root:

```sh
cargo build -p popcorn --locked
```

Run CLI tests:

```sh
cargo test -p popcorn --locked
```

Run the integration suite:

```sh
crates/cli/tests/integration.sh
```

## Architecture

See [docs/architecture.md](docs/architecture.md).
