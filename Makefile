PYTHON ?= python3
SHELL := bash

.PHONY: check shellcheck actionlint markdown file-sizes flat-directories docs release-smoke \
	rust-format rust-lint rust-test integration player server

check: brand-check shellcheck actionlint markdown file-sizes flat-directories docs release-smoke

shellcheck:
	scripts/check_shell.sh

actionlint:
	actionlint

markdown:
	$(PYTHON) scripts/check_markdown.py

file-sizes:
	$(PYTHON) scripts/check_file_sizes.py

flat-directories:
	$(PYTHON) scripts/check_flat_directories.py

docs:
	cd apps/docs && .venv/bin/mkdocs build --strict

release-smoke:
	$(PYTHON) scripts/check_release_workflow.py
	$(PYTHON) -B scripts/test_next_release_tag.py

rust-format:
	cargo fmt --all --check

rust-lint:
	mbx clippy --workspace --all-targets --locked -- -D warnings

rust-test:
	mbx test --workspace --locked

integration:
	crates/cli/tests/integration.sh

player:
	cd packages/player && bun install --frozen-lockfile && bun run build && bun run test

server:
	cd apps/server && mix deps.get --locked && mix test

.PHONY: brand-sync brand-check
brand-sync:
	$(PYTHON) scripts/sync_brand.py

brand-check:
	$(PYTHON) scripts/sync_brand.py --check
