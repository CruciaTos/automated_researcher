"""
app/main.py — FastAPI application entrypoint.

Start with:
    uvicorn backend.app.main:app --reload

For LAN access (phones/tablets on the same Wi-Fi):
    uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
    ↑ --host 0.0.0.0 is the only difference — it binds to all interfaces
      so other devices on your network can reach the server.
      Without it, the server only accepts connections from this machine.
"""

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.app.config import engine
from backend.app.models.base import Base

# Register all ORM models on Base.metadata BEFORE create_all() is called.
from backend.app.models import chunk, document, research_job  # noqa: F401
from backend.app.routers import health, jobs

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

# CORS — allow_origins=["*"] means any origin (including your phone on LAN)
# can call the API. This is intentional for local/LAN use. Tighten in prod.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(jobs.router)

logger.info("Application startup complete.")