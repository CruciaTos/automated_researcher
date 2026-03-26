"""
app/config.py — Centralised application configuration.

All settings are loaded from environment variables with safe defaults
for local development. In production, set these via a .env file or
your deployment platform's secret manager.
"""

import logging
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Database
# TODO_REQUIRED: DATABASE_URL — set to your production DB connection string.
# Examples:
#   postgresql+psycopg2://user:pass@host:5432/dbname
#   sqlite:///./sql_backend.app.db   (default — suitable for local dev only)
# ---------------------------------------------------------------------------
DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./sql_backend.app.db")

_connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    connect_args=_connect_args,
    echo=False,
    future=True,
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


# ---------------------------------------------------------------------------
# Settings singleton
# ---------------------------------------------------------------------------
class Settings:
    """
    Application-wide settings loaded from environment variables.
    Import the `settings` singleton rather than this class directly.
    """

    # ── Database ────────────────────────────────────────────────────────────
    database_url: str = DATABASE_URL

    # ── Ollama LLM ──────────────────────────────────────────────────────────
    # TODO_REQUIRED: OLLAMA_HOST — set if Ollama is not on localhost
    ollama_host: str = os.getenv("OLLAMA_HOST", "http://localhost:11434")
    # TODO_REQUIRED: OLLAMA_MODEL — override to use a different local model
    ollama_model: str = os.getenv("OLLAMA_MODEL", "qwen2.5:7b")
    ollama_timeout: int = int(os.getenv("OLLAMA_TIMEOUT", "120"))

    # ── Embeddings ──────────────────────────────────────────────────────────
    # Full HuggingFace repo ID is required; short names are NOT resolved.
    embedding_model: str = os.getenv("EMBEDDING_MODEL", "BAAI/bge-small-en-v1.5")

    # ── FAISS ───────────────────────────────────────────────────────────────
    faiss_index_dir: str = os.getenv("FAISS_INDEX_DIR", "data/indexes")

    # ── Job settings ─────────────────────────────────────────────────────────
    # Maximum number of sources to retrieve per job
    max_sources: int = int(os.getenv("MAX_SOURCES", "10"))
    # Maximum age (days) before a job is considered expired
    job_expiry_days: int = int(os.getenv("JOB_EXPIRY_DAYS", "3"))


settings = Settings()
