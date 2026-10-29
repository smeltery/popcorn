#!/usr/bin/env python3
"""Validate release workflow structure that actionlint cannot prove."""

from __future__ import annotations

import re
import sys
from pathlib import Path

WORKFLOW = Path(".github/workflows/release.yml")
EXPECTED_TARGETS = {
    "x86_64-unknown-linux-gnu",
    "x86_64-unknown-linux-musl",
    "aarch64-unknown-linux-gnu",
    "x86_64-apple-darwin",
    "aarch64-apple-darwin",
}
EXPECTED_RUNNERS = {
    "ubuntu-24.04",
    "macos-15",
}


def require(condition: bool, message: str, failures: list[str]) -> None:
    if not condition:
        failures.append(message)


def main() -> int:
    try:
        text = WORKFLOW.read_text(encoding="utf-8")
    except FileNotFoundError:
        print(f"release workflow not found: {WORKFLOW}", file=sys.stderr)
        return 1

    failures: list[str] = []
    targets = set(re.findall(r"target: ([A-Za-z0-9_-]+(?:-[A-Za-z0-9_]+)+)", text))
    runners = set(re.findall(r"(?:runs-on|os): ([A-Za-z0-9_.-]+)", text))

    require("tags:" in text and '"v*.*.*"' in text, "release workflow must run for v*.*.* tags", failures)
    require("workflow_dispatch:" in text, "release workflow must support manual dispatch", failures)
    require("draft:" in text and "Create the release as a draft" in text, "manual releases must expose a draft input", failures)
    require("permissions:\n  contents: write" in text, "release workflow must declare contents: write", failures)
    require(EXPECTED_TARGETS <= targets, f"missing release targets: {sorted(EXPECTED_TARGETS - targets)}", failures)
    require(runners <= EXPECTED_RUNNERS, f"unexpected runner labels: {sorted(runners - EXPECTED_RUNNERS)}", failures)
    require("${{ env.CARGO }} build -p popcorn --release --locked --target ${{ matrix.target }}" in text, "release build command must build popcorn for each target", failures)
    require('cp "target/${{ matrix.target }}/release/popcorn" "release-publish/popcorn-${{ matrix.target }}"' in text, "release workflow must collect target-named binaries", failures)
    require(re.search(r"uses: actions/upload-artifact@v[0-9]+\b", text) is not None, "release workflow must upload per-target artifacts", failures)
    require(re.search(r"uses: actions/download-artifact@v[0-9]+\b", text) is not None, "release workflow must download build artifacts", failures)
    require("shasum -a 256 popcorn-* > SHA256SUMS" in text, "release workflow must generate SHA256SUMS", failures)
    require(re.search(r"uses: softprops/action-gh-release@v[0-9]+\b", text) is not None, "release workflow must publish a GitHub release", failures)
    require("echo \"draft=false\" >> \"$GITHUB_OUTPUT\"" in text, "tag releases must publish visibly by default", failures)
    require("draft: ${{ needs.preflight.outputs.draft }}" in text, "release workflow must use preflight draft metadata", failures)
    require("prerelease: ${{ needs.preflight.outputs.is_prerelease }}" in text, "release workflow must preserve prerelease metadata", failures)
    require("make_latest: ${{ needs.preflight.outputs.make_latest }}" in text, "release workflow must set latest metadata from preflight", failures)

    if failures:
        print("Release workflow check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return 1

    print("release workflow check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
