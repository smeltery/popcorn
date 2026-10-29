#!/usr/bin/env python3
"""Regression tests for automatic release version selection."""

import unittest

from next_release_tag import next_tag


class ReleaseTagTests(unittest.TestCase):
    def test_empty_history(self):
        self.assertEqual(next_tag([], []), ("v0.1.0", True))

    def test_numeric_ordering(self):
        self.assertEqual(next_tag(["v3.9.9", "v3.10.12", "v2.99.99"], []), ("v3.10.13", True))

    def test_ignores_prereleases_and_malformed_tags(self):
        tags = ["v3.2.0", "v4.0.0-rc.1", "v4.0.0+build", "v9.01.0", "v5.0.0junk"]
        self.assertEqual(next_tag(tags, []), ("v3.2.1", True))

    def test_retry_reuses_tag_on_tested_commit(self):
        self.assertEqual(next_tag(["v3.2.0", "v3.2.1"], ["v3.2.1"]), ("v3.2.1", False))

    def test_prerelease_on_head_does_not_block_stable_release(self):
        self.assertEqual(next_tag(["v3.2.0", "v3.3.0-rc.1"], ["v3.3.0-rc.1"]), ("v3.2.1", True))


if __name__ == "__main__":
    unittest.main()
