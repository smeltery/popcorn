# Popcorn Contributor Docs

This directory is the contributor and operator handbook for the Popcorn
monorepo. It explains how the workspace fits together, how to work on it
locally, how CI and releases are expected to behave, and what security
properties contributors must preserve.

User-facing product documentation lives in [apps/docs/docs](../apps/docs/docs).
The files in this directory are for people changing, running, or reviewing the
repository.

## Reading Order

1. [architecture.md](architecture.md) explains the repository boundaries,
   recording lifecycle, and cross-component contracts.
1. [development.md](development.md) explains local setup, Flox, pre-commit,
   test selection, and common development workflows.
1. [operations.md](operations.md) explains CI, release automation, deployment
   assumptions, rollback posture, and operational checks.
1. [security.md](security.md) explains sensitive data handling, sharing risk,
   credential hygiene, and security review expectations.

Agent-facing instructions live in [AGENTS.md](../AGENTS.md).

## Repository Map

```mermaid
flowchart TD
  Root["Repository root"]
  Docs["docs/\nContributor and operator handbook"]
  Site["apps/docs/\nProduct documentation site"]
  Cli["crates/cli\npopcorn CLI"]
  Terminal["crates/avt\nTerminal parser and emulator"]
  Gif["crates/agg\nGIF renderer"]
  Player["packages/player\nBrowser player"]
  Server["apps/server\nPhoenix server"]
  CI[".github/workflows\nCI and release automation"]
  Flox[".flox/env\nPinned local tool environment"]

  Root --> Docs
  Root --> Site
  Root --> Cli
  Root --> Terminal
  Root --> Gif
  Root --> Player
  Root --> Server
  Root --> CI
  Root --> Flox
```

## Quality Gate

Use the smallest relevant check while iterating, then run the repository gate
before pushing:

```bash
flox activate
make check
pre-commit run --all-files
```

The root `make check` target is intentionally fast. It verifies shell scripts,
GitHub Actions syntax, markdown hygiene, repository file-size budgets, the
strict documentation build, and release workflow smoke coverage. Component test
suites still need to be run when a change affects that component.

## Component Checks

```mermaid
flowchart LR
  Change["Change"]
  Rust["Rust crates\nfmt, clippy, tests, CLI integration"]
  Player["Player\nBun build and tests"]
  Server["Server\nmix compile and tests"]
  Docs["Docs\nMkDocs strict build"]
  Gate["Repository gate\nmake check and pre-commit"]

  Change --> Rust
  Change --> Player
  Change --> Server
  Change --> Docs
  Rust --> Gate
  Player --> Gate
  Server --> Gate
  Docs --> Gate
```

Run the Rust checks when touching `crates/`, shared fixtures, release targets,
or CLI-facing documentation:

```bash
cargo fmt --all --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
crates/cli/tests/integration.sh
```

Run the player checks when touching `packages/player`, player assets, browser
embedding docs, or popcast parsing behavior visible in the browser:

```bash
cd packages/player
bun install --frozen-lockfile
bun run build
bun run test
```

Run the server checks when touching `apps/server`, database behavior, upload or
streaming flows, server-side rendering, or server configuration docs:

```bash
cd apps/server
mix deps.get --locked
npm ci --prefix assets
mix compile
DATABASE_URL=ecto://postgres:postgres@localhost/popcorn_test mix test
```

Run the product docs build when touching `apps/docs/docs`, docs navigation,
assets used by docs pages, or examples copied into user-facing material:

```bash
cd apps/docs
.venv/bin/mkdocs build --strict
```

## Documentation Expectations

Documentation changes should be specific enough that a new contributor can
follow the steps without private context. Prefer commands that work inside the
Flox environment, use `popcorn.example.com` for server examples, and clearly
label placeholders.

Keep docs aligned with automation. Do not describe package channels, hosted
services, deployment targets, or release artifacts as official until the
corresponding automation exists in this repository.
