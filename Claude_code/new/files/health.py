"""
app/routers/health.py — Health-check endpoints.

/health        — process liveness
/health/db     — database connectivity
/health/models — available Ollama models (used by the Flutter UI model picker)
"""

import logging

import requests
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session

from backend.app.config import settings
from backend.app.models.base import get_db

logger = logging.getLogger(__name__)

router = APIRouter(tags=["health"])


@router.get("/health", summary="Liveness check")
def health_check():
    """Returns 200 OK when the application process is alive."""
    return {"status": "ok"}


@router.get("/health/db", summary="Database connectivity check")
def health_db(db: Session = Depends(get_db)):
    """
    Returns 200 OK when the application can reach the database.
    Returns 503 if the database query fails.
    """
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "database": "reachable"}
    except Exception as exc:
        logger.exception("Database health check failed")
        raise HTTPException(
            status_code=503, detail=f"Database unreachable: {exc}"
        )


@router.get("/health/models", summary="List locally available Ollama models")
def get_available_models():
    """
    Queries the local Ollama server for all pulled models.

    Returns:
        models   — list of model name strings (e.g. ["qwen2.5:7b", "llama3:8b"])
        default  — the server's configured default model (OLLAMA_MODEL env var)

    Raises 503 if Ollama is unreachable so the Flutter UI can show a
    meaningful error instead of an empty list.
    """
    try:
        resp = requests.get(
            f"{settings.ollama_host}/api/tags",
            timeout=8,
        )
        resp.raise_for_status()
        data = resp.json()
        models = [m["name"] for m in data.get("models", [])]
        models.sort()
        logger.info("Ollama models available: %s", models)
        return {
            "models": models,
            "default": settings.ollama_model,
            "ollama_host": settings.ollama_host,
        }
    except requests.exceptions.ConnectionError:
        raise HTTPException(
            status_code=503,
            detail=f"Cannot reach Ollama at {settings.ollama_host}. "
                   "Is it running? (ollama serve)",
        )
    except requests.exceptions.Timeout:
        raise HTTPException(
            status_code=503,
            detail=f"Ollama at {settings.ollama_host} timed out.",
        )
    except Exception as exc:
        logger.exception("Failed to list Ollama models")
        raise HTTPException(
            status_code=503, detail=f"Ollama error: {exc}"
        )
