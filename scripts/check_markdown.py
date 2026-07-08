#!/usr/bin/env python3
"""Lint tracked Markdown for formatting hygiene."""

from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_PARTS = {
    ".git",
    ".flox",
    ".venv",
    "__pycache__",
    "build",
    "dist",
    "node_modules",
    "site",
    "target",
}

Violation = tuple[str, int, str]


def tracked_markdown() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "*.md"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        text=True,
    )
    return [
        Path(line)
        for line in result.stdout.splitlines()
        if line and not (set(Path(line).parts) & EXCLUDED_PARTS)
    ]


def cell_count(row: str) -> int:
    stripped = row.strip()
    body = stripped[1:] if stripped.startswith("|") else stripped
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]

    count = 1
    index = 0
    while index < len(body):
        char = body[index]
        if char == "\\":
            index += 2
            continue
        if char == "|":
            count += 1
        index += 1
    return count


def is_separator(row: str) -> bool:
    cells = row.strip().strip("|").split("|")
    if not cells:
        return False

    for cell in cells:
        token = cell.strip()
        if token == "" or set(token) - {"-", ":"} or "-" not in token:
            return False
    return True


def check_file(path: Path) -> list[Violation]:
    violations: list[Violation] = []
    raw = (ROOT / path).read_bytes()

    if raw and not raw.endswith(b"\n"):
        violations.append((path.as_posix(), 0, "file does not end with a newline"))
    if raw.endswith(b"\n\n"):
        violations.append((path.as_posix(), 0, "file ends with a blank line"))

    text = raw.decode("utf-8", errors="replace")
    lines = text.split("\n")
    in_fence = False

    for lineno, line in enumerate(lines, start=1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if line != line.rstrip():
            violations.append((path.as_posix(), lineno, "trailing whitespace"))
        if "\t" in line:
            violations.append((path.as_posix(), lineno, "hard tab in Markdown content"))

    check_tables(path, lines, violations)
    check_mermaid(path, lines, violations)
    return violations


def check_mermaid(path: Path, lines: list[str], violations: list[Violation]) -> None:
    in_mermaid = False
    for lineno, line in enumerate(lines, start=1):
        if line.lstrip().startswith("```"):
            fence_token = line.lstrip()[3:].strip().lower()
            if not in_mermaid and fence_token == "mermaid":
                in_mermaid = True
            elif in_mermaid:
                in_mermaid = False
            continue
        if not in_mermaid:
            continue
        if "`" in line:
            violations.append((path.as_posix(), lineno, "backtick in mermaid block"))
        if "[" in line and "]" in line and line.count('"') % 2 == 1:
            violations.append((path.as_posix(), lineno, "unbalanced mermaid node-label quotes"))


def check_tables(path: Path, lines: list[str], violations: list[Violation]) -> None:
    in_fence = False
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            index += 1
            continue

        if not in_fence and "|" in line and index + 1 < len(lines) and is_separator(lines[index + 1]):
            header_cols = cell_count(line)
            separator_cols = cell_count(lines[index + 1])
            if separator_cols != header_cols:
                violations.append(
                    (
                        path.as_posix(),
                        index + 2,
                        f"table separator has {separator_cols} columns; header has {header_cols}",
                    )
                )

            row_index = index + 2
            while row_index < len(lines) and lines[row_index].strip().startswith("|"):
                row_cols = cell_count(lines[row_index])
                if row_cols != header_cols:
                    violations.append(
                        (
                            path.as_posix(),
                            row_index + 1,
                            f"table row has {row_cols} columns; header has {header_cols}",
                        )
                    )
                row_index += 1
            index = row_index
            continue
        index += 1


def main() -> int:
    failures: list[Violation] = []
    files = tracked_markdown()
    for path in files:
        failures.extend(check_file(path))

    if not failures:
        print(f"markdown check passed: {len(files)} files")
        return 0

    print("markdown check failed:")
    for file_path, lineno, reason in failures:
        location = f"{file_path}:{lineno}" if lineno else file_path
        print(f"  {location}: {reason}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
