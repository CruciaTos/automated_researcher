"""
app/routers/health.py — Health-check endpoint.

Used by load balancers, container orchestrators (K8s liveness probe), and
uptime monitors to verify the application is running.
"""

import logging

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.models.base import get_db

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
        from fastapi import HTTPException
        raise HTTPException(status_code=503, detail=f"Database unreachable: {exc}")
