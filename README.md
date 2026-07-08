# popcorn

popcorn is a dotbrains monorepo for terminal session recording, playback,
streaming, hosting, and related tooling.

The workspace contains the `popcorn` CLI and the related player, server, docs,
terminal, and GIF rendering packages. Recordings use the `.pop` file extension
and Popcorn-facing command, configuration, and release naming.

## Packages

- `crates/cli`: Rust command-line recorder, streamer, player, and converter.
- `crates/avt`: virtual terminal primitives used by the CLI, player, server,
  and GIF renderer.
- `crates/agg`: GIF renderer, packaged as `popcorn-gif`.
- `packages/player`: web player for `.pop` recordings and live streams.
- `apps/server`: hosting and sharing server for recordings and streams.
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

## License

Popcorn is licensed under the PolyForm Shield License 1.0.0. See
[LICENSE](LICENSE) for details.
