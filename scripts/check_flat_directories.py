#!/usr/bin/env python3
"""Check tracked repository directories against direct-file count budgets."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any

DEFAULT_BUDGET_PATH = Path("scripts/flat-directory-budgets.json")
CHECKED_ROOTS = (
    ".github",
    "apps",
    "crates",
    "docs",
    "packages",
    "scripts",
)
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
    "uploads",
}
EXCLUDED_FILENAMES = {
    "package-lock.json",
}


def load_budgets(path: Path) -> tuple[int, dict[str, int]]:
    try:
        raw: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise SystemExit(f"Budget file not found: {path}") from None
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Budget file is invalid JSON: {path}: {exc}") from None

    default = raw.get("default_files")
    if not isinstance(default, int) or default < 1:
        raise SystemExit("Budget file must define a positive integer default_files")

    directories = raw.get("directories", {})
    if not isinstance(directories, dict):
        raise SystemExit("Budget file directories value must be an object")

    budgets: dict[str, int] = {}
    for dir_path, config in directories.items():
        if not isinstance(dir_path, str):
            raise SystemExit("Budget directory paths must be strings")
        if isinstance(config, int):
            limit = config
        elif isinstance(config, dict):
            limit = config.get("limit")
        else:
            raise SystemExit(f"Budget for {dir_path} must be an integer or object")
        if not isinstance(limit, int) or limit < 1:
            raise SystemExit(f"Budget for {dir_path} must define a positive integer limit")
        budgets[dir_path] = limit

    return default, budgets


def git_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", *CHECKED_ROOTS],
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return [Path(line) for line in result.stdout.splitlines() if line]


def should_count(path: Path) -> bool:
    return (
        path.name not in EXCLUDED_FILENAMES
        and not EXCLUDED_PARTS.intersection(path.parts)
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--budget-file",
        type=Path,
        default=DEFAULT_BUDGET_PATH,
        help=f"Path to budget JSON (default: {DEFAULT_BUDGET_PATH})",
    )
    args = parser.parse_args()

    default_budget, dir_budgets = load_budgets(args.budget_file)
    counts: Counter[str] = Counter()

    for path in git_files():
        if should_count(path):
            counts[path.parent.as_posix()] += 1

    failures: list[str] = []
    for dir_path, file_count in sorted(counts.items()):
        budget = dir_budgets.get(dir_path, default_budget)
        if file_count > budget:
            failures.append(f"{dir_path}: {file_count} files > budget {budget}")

    if failures:
        print("Flat directory budget exceeded:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print(f"flat directory check passed ({default_budget} file default)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
