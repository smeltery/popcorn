# Architecture

popcorn is organized as a monorepo so the CLI, player, server, terminal
emulation, and documentation can evolve against one branded recording format.

## Packages

- `crates/cli` owns local recording, playback, conversion, streaming, and upload
  client behavior.
- `packages/player` is reserved for the browser player.
- `apps/server` is reserved for hosting recordings and streams.
- `packages/terminal` is reserved for shared virtual terminal behavior.
- `apps/docs` is reserved for the documentation site.

## Recording Format

New recordings use the `.pop` extension and the user-facing `popcast` format
name. The CLI keeps compatibility with existing v1/v2/v3 historical terminal recording payload
shapes where useful so older fixtures and imports can still be read.

## Terminal Execution

The CLI records commands through a PTY-backed execution path. On Unix platforms
this uses `nix::pty::forkpty` and propagates terminal resizes, input, output,
and process exit status into the session event stream.
