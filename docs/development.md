# Development

This guide describes how to set up the repository, choose the right checks,
work with each component, and keep local results aligned with CI.

## Tooling Model

Popcorn uses Flox to provide the common toolchain needed by the monorepo. The
environment lives at `.flox/env/manifest.toml` and is the recommended entry
point for local work.

```bash
flox activate
```

The environment provides Git/GitHub tooling, Rust bootstrap through `rustup`,
Node 24, Python 3.12 for docs, Elixir tooling, `fd`, ImageMagick, `actionlint`,
`pre-commit`, `shellcheck`, and shared command-line utilities. The activation
hook installs the Rust 1.87 toolchain and prepares `apps/docs/.venv`.

```mermaid
flowchart TD
  Clone["Fresh clone"]
  Flox["flox activate"]
  Rust["Rust toolchain\n1.87 with clippy and rustfmt"]
  Node["Node 24\nplayer and server assets"]
  Python["Python 3.12\nMkDocs virtualenv"]
  Elixir["Elixir and Hex tooling\nserver checks"]
  Hooks["pre-commit install"]
  Ready["Ready to develop"]

  Clone --> Flox
  Flox --> Rust
  Flox --> Node
  Flox --> Python
  Flox --> Elixir
  Flox --> Hooks
  Hooks --> Ready
```

Install local hooks once per clone:

```bash
pre-commit install
```

Run the repository gate manually with:

```bash
make check
pre-commit run --all-files
```

## Daily Workflow

Use this loop for most changes:

```mermaid
stateDiagram-v2
  [*] --> Sync
  Sync --> SelectScope
  SelectScope --> Edit
  Edit --> FocusedChecks
  FocusedChecks --> Edit: failure
  FocusedChecks --> RepoGate: pass
  RepoGate --> Commit: pass
  RepoGate --> Edit: failure
  Commit --> Push
  Push --> CI
  CI --> Done: pass
  CI --> Edit: failure
```

1. Sync the branch and inspect existing changes with `git status --short`.
1. Identify the affected component before editing.
1. Run focused checks for that component while iterating.
1. Run `make check` and relevant full component checks before pushing.
1. Push and verify the GitHub Actions run.

## Choosing Checks

| Change area | Minimum focused check | Before push |
| --- | --- | --- |
| Rust CLI or shared Rust crates | `cargo test -p <crate>` or targeted test | Full Rust workspace checks and CLI integration when behavior changes. |
| Terminal parser behavior | Targeted parser tests or fixtures | Full Rust workspace tests and any affected renderer checks. |
| Browser player | Targeted package test | `bun run build` and `bun run test` in `packages/player`. |
| Server code | Targeted `mix test` file | Server compile and full `mix test` with PostgreSQL. |
| Docs content | Markdown gate or MkDocs build | `make check`. |
| Workflows | `actionlint` | `make check`, then verify GitHub Actions after push. |
| Flox environment | `flox activate` | `make check` inside Flox and a CI run. |

## Rust Workspace

The Rust workspace contains:

- `crates/cli`: the `popcorn` command-line application.
- `crates/avt`: terminal parsing and virtual terminal behavior.
- `crates/agg`: GIF rendering.

Common Rust checks:

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
crates/cli/tests/integration.sh
```

Useful targeted commands:

```bash
cargo test -p popcorn
cargo test -p popcorn-terminal
cargo test -p popcorn-gif
cargo clippy -p popcorn --all-targets --locked -- -D warnings
```

When changing CLI behavior, update command help, examples, fixtures, and product
docs together. CLI behavior is user-facing even when the implementation change
is small.

Import adapters should live at the CLI boundary and normalize into popcast
events before reaching shared encoders. Add focused parser tests for binary edge
cases, command tests for `popcorn convert`, and user-facing docs under
`apps/docs/docs/manual/cli`.

## Player

The player package owns browser playback. It includes Rust/WASM pieces,
JavaScript packaging, browser integration tests, themes, fonts, and rendering
fixtures.

```bash
cd packages/player
bun install --frozen-lockfile
bun run build
bun run test
```

Keep generated `dist/` artifacts out of source changes unless a release process
explicitly asks for them. If a player change affects embedded examples, update
the relevant pages under `apps/docs/docs/manual/player`.

## Server

The server is a Phoenix application backed by PostgreSQL. CI runs PostgreSQL 16
as a service. Local runs need an equivalent database available through
`DATABASE_URL`.

```bash
cd apps/server
mix deps.get --locked
npm ci --prefix assets
mix compile
DATABASE_URL=ecto://postgres:postgres@localhost/popcorn_test mix test
```

Targeted examples:

```bash
cd apps/server
DATABASE_URL=ecto://postgres:postgres@localhost/popcorn_test mix test test/popcorn/file_cache_test.exs
DATABASE_URL=ecto://postgres:postgres@localhost/popcorn_test mix test test/popcorn_web
```

Server changes often cross several layers. Keep context APIs, LiveView or
controller behavior, templates, background jobs, and tests aligned.

```mermaid
flowchart LR
  Request["HTTP or CLI request"]
  Endpoint["Endpoint/router"]
  Web["Controller or LiveView"]
  Context["Domain context"]
  DB["PostgreSQL"]
  Job["Background job"]
  Cache["File cache"]

  Request --> Endpoint
  Endpoint --> Web
  Web --> Context
  Context --> DB
  Context --> Job
  Job --> Cache
```

## Product Docs

Product docs are built with MkDocs from `apps/docs`.

```bash
cd apps/docs
.venv/bin/mkdocs build --strict
```

Write product docs for users, not repository maintainers. Use current Popcorn
commands, `.pop` examples, and placeholders such as `popcorn.example.com`.
Avoid documenting package managers, hosting assumptions, or service names unless
the repository contains automation and tests for that path.

## Root Docs

Root docs in `docs/` should explain how to work on and operate this repository.
They may include internal detail that does not belong in product docs, such as
CI gates, component boundaries, release workflow behavior, and security review
expectations.

Mermaid diagrams are allowed and encouraged when they clarify flow, ownership,
or state transitions. Keep diagrams close to the prose they explain.

## Pre-commit

The root `.pre-commit-config.yaml` wraps the same fast checks used by the CI
gate:

- shell script linting,
- GitHub Actions linting,
- markdown hygiene,
- repository file-size budgets,
- flat directory budgets,
- strict docs build,
- release workflow smoke validation.

Run hooks before pushing:

```bash
pre-commit run --all-files
```

If a hook fails, fix the underlying issue rather than bypassing the hook. A
local hook failure usually predicts a CI gate failure.

## File-size Budget

The repository gate enforces file-size budgets through
`scripts/check_file_sizes.py` and `scripts/file-size-budgets.json`. The default
budget is intentionally conservative so generated files, copied dependencies,
or accidental build output do not enter the repository unnoticed.

If a large file is intentional, add the narrowest possible exception with a
reason in review. Prefer generated assets, package downloads, or release
artifacts to live outside normal source control unless they are needed for tests
or documentation.

Before adding a new exception, check whether the file can be split around a real
domain boundary. Good splits usually separate parsing from rendering, command
dispatch from business logic, fixtures from assertions, or generated assets from
hand-written source. Avoid moving old broad modules during unrelated feature
work; make that a dedicated refactor with regression tests.

## Flat-directory Budget

The repository gate also enforces direct-file count budgets through
`scripts/check_flat_directories.py` and
`scripts/flat-directory-budgets.json`. The default budget catches directories
that are turning into broad catch-all namespaces.

If a directory needs a higher limit, record the narrow exception and reason in
the budget file. Framework-owned directories, chronological migrations, and
asset buckets may be valid exceptions. New source code should usually create a
domain subdirectory before it reaches the default limit.

## Workflow Changes

When editing `.github/workflows`, run:

```bash
actionlint
make release-smoke
make check
```

The CI workflows use Blacksmith runner labels. If a workflow needs a new runner
shape, update the actionlint configuration and verify the new label in a real CI
run.

## Commit And Push Checklist

```mermaid
flowchart TD
  Status["git status --short"]
  Diff["review git diff"]
  Focused["focused component checks"]
  Gate["make check"]
  Hooks["pre-commit run --all-files"]
  Commit["conventional commit"]
  Push["git push"]
  CI["verify CI"]

  Status --> Diff
  Diff --> Focused
  Focused --> Gate
  Gate --> Hooks
  Hooks --> Commit
  Commit --> Push
  Push --> CI
```

Use conventional commit prefixes such as `feat:`, `fix:`, `docs:`, `ci:`,
`test:`, `refactor:`, and `chore:`. Keep the subject short, imperative, and
focused on why the change exists.
