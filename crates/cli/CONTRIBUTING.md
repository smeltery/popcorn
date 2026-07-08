# Contributing

This package follows the repository-level guidance in [../../AGENTS.md](../../AGENTS.md).

Before opening a PR for CLI changes, run:

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets --locked
cargo test --workspace --locked
crates/cli/tests/integration.sh
```

Keep user-facing terminology aligned with Popcorn:

- CLI/product: `popcorn`
- Recording files: `.pop`
- Recording format: `popcast`
- Environment variables: `POPCORN_*`
