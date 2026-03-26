"""
app/dependencies.py — FastAPI dependency re-exports.

The canonical `get_db` dependency lives in `backend.app.models.base` to keep the
import graph acyclic. This module re-exports it so any code that previously
imported `from backend.app.dependencies import get_db` continues to work unchanged.
"""

from backend.app.models.base import get_db  # noqa: F401  (intentional re-export)
