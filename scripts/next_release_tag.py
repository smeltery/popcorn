#!/usr/bin/env python3
"""Select a stable release tag without modifying Git; emit Actions outputs."""

from __future__ import annotations

import re
import subprocess

STABLE_TAG = re.compile(r"v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")


def stable_tags(tags: list[str]) -> list[tuple[int, int, int]]:
    return sorted(
        tuple(map(int, match.groups()))
        for tag in tags
        if (match := STABLE_TAG.fullmatch(tag))
    )


def next_tag(tags: list[str], head_tags: list[str]) -> tuple[str, bool]:
    existing = stable_tags(head_tags)
    if existing:
        version = existing[-1]
        created = False
    else:
        versions = stable_tags(tags)
        if versions:
            major, minor, patch = versions[-1]
            version = (major, minor, patch + 1)
        else:
            version = (0, 1, 0)
        created = True
    return "v" + ".".join(map(str, version)), created


def git_tags(*args: str) -> list[str]:
    return subprocess.check_output(["git", "tag", *args], text=True).splitlines()


def main() -> None:
    tag, created = next_tag(git_tags("--list"), git_tags("--points-at", "HEAD"))
    print(f"tag={tag}")
    print(f"created={str(created).lower()}")


if __name__ == "__main__":
    main()
