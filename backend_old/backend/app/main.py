"""
app/main.py — FastAPI application entrypoint.

Start with:
    uvicorn app.main:app --reload
"""

import logging

from fastapi import FastAPI

from app.config import engine
from app.models.base import Base

# Register all ORM models on Base.metadata BEFORE create_all() is called.
from app.models import chunk, document, research_job  # noqa: F401
from app.routers import health, jobs

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s — %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Database bootstrap
# ---------------------------------------------------------------------------
Base.metadata.create_all(bind=engine)
logger.info("Database tables verified / created.")

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Research API",
    description="Automated research pipeline powered by local LLMs.",
    version="0.1.0",
)

app.include_router(health.router)
app.include_router(jobs.router)

logger.info("Application startup complete.")
