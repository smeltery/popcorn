# Development

## CLI

Build:

```sh
cargo build -p popcorn --locked
```

Test:

```sh
cargo test -p popcorn --locked
```

Integration test:

```sh
crates/cli/tests/integration.sh
```

Format and lint:

```sh
cargo fmt --all --check
cargo clippy --workspace --all-targets --locked
```
