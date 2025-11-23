from __future__ import annotations

import os
from typing import Generator

import django
import pytest
from django.test.utils import (
    setup_databases,
    setup_test_environment,
    teardown_databases,
    teardown_test_environment,
)

# Ensure Django knows which settings module to use before anything tries to import
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "fitmatrix.settings")

# Initialise Django so model imports work during test collection. If Django is already
# initialised we ignore the re-entrant setup error so test discovery still succeeds.
try:
    django.setup()
except RuntimeError as exc:  # pragma: no cover - defensive guard
    if "populate() isn't reentrant" not in str(exc):
        raise


@pytest.fixture(scope="session", autouse=True)
def _django_test_environment() -> Generator[None, None, None]:
    """Replicate the essentials of Django's test runner for pytest."""

    setup_test_environment()
    old_config = setup_databases(verbosity=0, interactive=False, keepdb=False)
    try:
        yield
    finally:
        teardown_databases(old_config, verbosity=0)
        teardown_test_environment()
