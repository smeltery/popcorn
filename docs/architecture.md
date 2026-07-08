# Architecture

Popcorn is organized as a monorepo so the CLI, terminal model, browser player,
server, renderers, release workflows, and documentation evolve against one
recording format and one product vocabulary.

The core contract is the `.pop` recording file. The CLI creates it, the player
renders it, the server stores and shares it, the docs explain it, and release
automation ships tools that understand it.

## System Boundaries

```mermaid
flowchart TB
  User["User terminal"]
  CLI["popcorn CLI\nrecord, play, convert, stream, upload"]
  Format[".pop recording\npopcast event stream"]
  Terminal["Terminal engine\nparser, screen model, timing"]
  GIF["GIF renderer\nterminal frames to animation"]
  Player["Browser player\nWASM and JavaScript"]
  Server["Popcorn server\naccounts, uploads, streams, sharing"]
  Storage["Storage\nlocal disk or configured object storage"]
  Docs["Documentation\nmanuals, examples, reference"]

  User --> CLI
  CLI --> Format
  Format --> Terminal
  Terminal --> CLI
  Terminal --> GIF
  Terminal --> Player
  CLI --> Server
  Server --> Storage
  Storage --> Server
  Server --> Player
  Docs -. explains .-> CLI
  Docs -. explains .-> Player
  Docs -. explains .-> Server
  Docs -. explains .-> Format
```

## Package Responsibilities

| Path | Responsibility | Primary checks |
| --- | --- | --- |
| `crates/cli` | Command-line interface, PTY recording, playback, conversion, upload, streaming client behavior. | `cargo fmt`, `cargo clippy`, `cargo test`, CLI integration script. |
| `crates/avt` | Terminal event parsing, virtual terminal state, text extraction, parser tests and fuzz helpers. | Rust workspace checks, parser fixtures, fuzz helper where relevant. |
| `crates/agg` | GIF generation from terminal recordings. | Rust workspace checks and renderer-specific tests. |
| `packages/player` | Browser player package, WASM build, JavaScript API, theme and rendering behavior. | `bun run build`, Playwright or package tests. |
| `apps/server` | Phoenix application for accounts, uploads, hosted recordings, streaming, admin surfaces, file cache, and background jobs. | `mix compile`, `mix test`, asset install, PostgreSQL-backed tests. |
| `apps/docs` | Product documentation site, examples, product manuals, and published docs assets. | `mkdocs build --strict`. |
| `docs` | Contributor and operator documentation for this repository. | Markdown gate, repository gate. |
| `.github` | CI and release workflows. | `actionlint`, release smoke validation, GitHub Actions CI. |
| `.flox` | Reproducible local tool environment. | `flox activate`, repository gate. |

## Recording Lifecycle

```mermaid
sequenceDiagram
  autonumber
  actor User
  participant CLI as popcorn CLI
  participant PTY as PTY session
  participant File as .pop file
  participant Player as Browser player
  participant Server as Popcorn server

  User->>CLI: popcorn rec demo.pop
  CLI->>PTY: start shell or command
  PTY-->>CLI: output, input, resize, exit status
  CLI->>File: write metadata and timed events
  User->>CLI: popcorn play demo.pop
  CLI->>File: read recording
  CLI->>User: replay terminal session
  User->>CLI: popcorn upload demo.pop
  CLI->>Server: authenticated upload
  Server->>Server: validate and store recording
  Server-->>User: sharing URL
  User->>Player: open shared recording
  Player->>Server: fetch recording
  Player->>User: render interactive playback
```

The lifecycle has three important invariants:

- A valid `.pop` recording must be readable without network access.
- Playback should preserve terminal timing and screen state, but must not
  require the original command environment.
- Upload and sharing are optional layers over the local recording format.

## Recording Format Contract

New recordings use the `.pop` extension and the user-facing `popcast` format
name. The format carries session metadata and a timed terminal event stream.
Readers may support older historical payload shapes when useful for fixtures or
imports, but new documentation and examples should use `.pop`.

```mermaid
classDiagram
  class Popcast {
    +metadata
    +events
    +duration
    +terminal_size
  }

  class Metadata {
    +version
    +command
    +shell
    +title
    +environment
  }

  class Event {
    +timestamp
    +type
    +payload
  }

  class OutputEvent {
    +bytes
  }

  class ResizeEvent {
    +columns
    +rows
  }

  class MarkerEvent {
    +label
  }

  Popcast --> Metadata
  Popcast --> Event
  Event <|-- OutputEvent
  Event <|-- ResizeEvent
  Event <|-- MarkerEvent
```

Compatibility code should stay at the edges. Internals should normalize into
the current domain model as early as possible, so rendering, text extraction,
server processing, and tests do not need to know every historical detail.

Import adapters follow that same rule. For example, the CLI ttyrec importer
reads ttyrec frames at the command boundary, normalizes them into popcast output
events, and then hands those events to the normal encoders.

```mermaid
flowchart LR
  Ttyrec["ttyrec input"]
  Adapter["Import adapter"]
  Events["Popcast events"]
  Encoders["Shared encoders"]
  Outputs[".pop, text, or raw output"]

  Ttyrec --> Adapter
  Adapter --> Events
  Events --> Encoders
  Encoders --> Outputs
```

## CLI Execution Path

The CLI records commands through a PTY-backed execution path on Unix platforms.
The recorder starts the requested command or shell, relays input and terminal
resize events, captures output with timing information, and writes the final
exit status.

```mermaid
flowchart LR
  Args["CLI args and config"]
  Recorder["Recorder"]
  PTY["PTY child process"]
  Events["Timed event stream"]
  Writer["Popcast writer"]
  File["demo.pop"]

  Args --> Recorder
  Recorder --> PTY
  PTY --> Events
  Recorder --> Events
  Events --> Writer
  Writer --> File
```

Recording code should avoid hidden process-global state. Terminal dimensions,
environment values, output paths, API endpoints, and authentication should come
from explicit configuration, command arguments, or well-documented environment
variables.

## Playback And Rendering Path

Rendering uses a terminal model rather than treating output as plain text. This
keeps cursor movement, color, resizing, alternate screen behavior, and control
sequences consistent across CLI playback, GIF generation, and browser playback.

```mermaid
flowchart TD
  File[".pop file"]
  Parser["Event parser"]
  Clock["Playback clock"]
  Terminal["Virtual terminal state"]
  CLI["CLI renderer"]
  WASM["WASM player core"]
  GIF["GIF frame renderer"]

  File --> Parser
  Parser --> Clock
  Clock --> Terminal
  Terminal --> CLI
  Terminal --> WASM
  Terminal --> GIF
```

When changing terminal behavior, prefer shared parser or terminal fixtures over
component-local assumptions. A parser fix that only updates the browser player
but not CLI playback is usually incomplete.

## Server Architecture

The server is a Phoenix application. It owns hosted recording workflows,
streaming workflows, account state, admin surfaces, background jobs, and cached
derived assets such as rendered images.

```mermaid
flowchart TB
  Browser["Browser"]
  CLI["popcorn CLI"]
  Endpoint["Phoenix endpoint"]
  Controllers["Controllers and LiveViews"]
  Contexts["Domain contexts\naccounts, recordings, streaming"]
  Repo["PostgreSQL"]
  Jobs["Oban jobs"]
  Cache["File cache"]
  Storage["Recording storage"]

  Browser --> Endpoint
  CLI --> Endpoint
  Endpoint --> Controllers
  Controllers --> Contexts
  Contexts --> Repo
  Contexts --> Jobs
  Jobs --> Repo
  Jobs --> Cache
  Contexts --> Storage
  Cache --> Storage
```

The server should keep external side effects behind clear boundaries:

- Database reads and writes go through contexts.
- Background work goes through Oban workers.
- Cached derived files are disposable and rebuildable.
- Uploaded recordings are source data and require explicit retention and backup
  decisions.
- Server examples should use `popcorn.example.com` unless documenting a real
  local development URL.

## CI And Release Boundary

CI is part of the architecture because it defines what the repository promises
on every push. The main workflow checks the repository gate, Rust workspace,
browser player, Phoenix server, docs, release workflow shape, and platform
smoke builds.

```mermaid
flowchart LR
  Push["Push or PR"]
  Gate["Repository gate"]
  Rust["Rust workspace"]
  Player["Browser player"]
  Server["Server"]
  Docs["Docs"]
  Platforms["Platform smoke builds"]
  Result["Merge or release confidence"]

  Push --> Gate
  Push --> Rust
  Push --> Player
  Push --> Server
  Push --> Docs
  Push --> Platforms
  Gate --> Result
  Rust --> Result
  Player --> Result
  Server --> Result
  Docs --> Result
  Platforms --> Result
```

Release automation should only publish artifacts that CI can build and smoke
test. Documentation should not claim support for package channels or deployment
targets that do not have automation in this repository.

## Design Rules

- Keep `.pop` as the primary external recording contract.
- Keep user-facing terminology consistent: Popcorn for the product and popcast
  for the recording format.
- Keep compatibility handling near parsers, importers, and migration code.
- Keep local development commands reproducible through Flox whenever practical.
- Keep CI gates close to the developer gate so local failures match remote
  failures.
- Keep server deployment examples self-hosted and placeholder-based unless the
  repository contains production automation for a different path.
