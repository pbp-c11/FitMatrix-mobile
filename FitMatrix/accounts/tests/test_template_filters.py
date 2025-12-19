from __future__ import annotations

from django.test import SimpleTestCase

from accounts.templatetags.custom_filters import startswith


class StartsWithFilterTests(SimpleTestCase):
    def test_returns_true_for_prefix(self) -> None:
        self.assertTrue(startswith("FitMatrix", "Fit"))

    def test_handles_blank_values(self) -> None:
        self.assertFalse(startswith("", "Fit"))
        self.assertFalse(startswith(None, "Fit"))

    def test_casts_non_string_value(self) -> None:
        self.assertTrue(startswith(12345, "123"))
