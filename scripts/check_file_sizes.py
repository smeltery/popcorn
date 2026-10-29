#!/usr/bin/env python3
"""Check tracked source, docs, scripts, and workflows against line budgets."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

DEFAULT_BUDGET_PATH = Path("scripts/file-size-budgets.json")
CHECKED_ROOTS = (
    ".github",
    "apps",
    "crates",
    "docs",
    "packages",
    "scripts",
)
CHECKED_SUFFIXES = {
    ".css",
    ".ex",
    ".exs",
    ".html",
    ".js",
    ".json",
    ".md",
    ".mjs",
    ".py",
    ".rs",
    ".sh",
    ".toml",
    ".ts",
    ".yaml",
    ".yml",
}
EXCLUDED_PARTS = {
    ".git",
    ".flox",
    ".venv",
    "__pycache__",
    "_build",
    "deps",
    "dist",
    "node_modules",
    "playwright-report",
    "site",
    "target",
    "test-results",
}
EXCLUDED_FILENAMES = {
    "package-lock.json",
}
EXCLUDED_PATHS = {
    "apps/docs/docs/stylesheets/player-3.8.0.css",
    "apps/docs/docs/stylesheets/popcorn-player.css",
}


def load_budgets(path: Path) -> tuple[int, dict[str, int]]:
    try:
        raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"Budget file not found: {path}") from None
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Budget file is invalid JSON: {path}: {exc}") from None

    default = raw.get("default_lines")
    if not isinstance(default, int) or default < 1:
        raise SystemExit("Budget file must define a positive integer default_lines")

    files = raw.get("files", {})
    if not isinstance(files, dict):
        raise SystemExit("Budget file files value must be an object")

    budgets: dict[str, int] = {}
    for file_path, budget in files.items():
        if not isinstance(file_path, str):
            raise SystemExit("Budget file paths must be strings")
        if not isinstance(budget, int) or budget < 1:
            raise SystemExit(f"Budget for {file_path} must be a positive integer")
        budgets[file_path] = budget

    return default, budgets


def git_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", *CHECKED_ROOTS],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return [Path(line) for line in result.stdout.splitlines() if line]


def should_check(path: Path) -> bool:
    relative_path = path.as_posix()

    return (
        relative_path not in EXCLUDED_PATHS
        and path.name not in EXCLUDED_FILENAMES
        and path.suffix in CHECKED_SUFFIXES
        and not EXCLUDED_PARTS.intersection(path.parts)
        and "fixtures" not in path.parts
        and "tests/assets" not in relative_path
    )


def count_lines(path: Path) -> int:
    with path.open("rb") as file:
        return sum(1 for _ in file)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--budget-file",
        type=Path,
        default=DEFAULT_BUDGET_PATH,
        help=f"Path to budget JSON (default: {DEFAULT_BUDGET_PATH})",
    )
    args = parser.parse_args()

    default_budget, file_budgets = load_budgets(args.budget_file)
    failures: list[str] = []

    for path in sorted(git_files()):
        if not path.is_file() or not should_check(path):
            continue
        relative_path = path.as_posix()
        line_count = count_lines(path)
        budget = file_budgets.get(relative_path, default_budget)
        if line_count > budget:
            failures.append(f"{relative_path}: {line_count} lines > budget {budget}")

    if failures:
        print("File size budget exceeded:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print(f"file size check passed ({default_budget} line default)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
