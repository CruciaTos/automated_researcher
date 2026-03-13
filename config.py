# config.py
"""Configuration module using python-dotenv.

Provides a Settings class that loads required environment variables.
The required variables are:
- DATABASE_URL
- REDIS_URL
- OLLAMA_URL
- VECTOR_STORE_PATH
- RAW_DOCS_PATH

The module uses `load_dotenv` to read a `.env` file located in the
project root (or any location python-dotenv can discover). If a variable
is missing, an informative `ValueError` is raised.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

# Load .env file from the project root (or any parent directory)
load_dotenv()

@dataclass(frozen=True)
class Settings:
    """Immutable settings container for environment configuration.

    Attributes:
        database_url (str): URL for the primary database.
        redis_url (str): URL for the Redis instance.
        ollama_url (str): URL for the Ollama service.
        vector_store_path (Path): Filesystem path for vector store data.
        raw_docs_path (Path): Filesystem path for raw document storage.
    """

    database_url: str = os.getenv("DATABASE_URL", "")
    redis_url: str = os.getenv("REDIS_URL", "")
    ollama_url: str = os.getenv("OLLAMA_URL", "")
    vector_store_path: Path = Path(os.getenv("VECTOR_STORE_PATH", ""))
    raw_docs_path: Path = Path(os.getenv("RAW_DOCS_PATH", ""))

    def __post_init__(self) -> None:
        # Validate required variables are present and non‑empty
        missing = [
            name
            for name, value in {
                "DATABASE_URL": self.database_url,
                "REDIS_URL": self.redis_url,
                "OLLAMA_URL": self.ollama_url,
                "VECTOR_STORE_PATH": str(self.vector_store_path),
                "RAW_DOCS_PATH": str(self.raw_docs_path),
            }.items()
            if not value
        ]
        if missing:
            raise ValueError(
                f"Missing required environment variable(s): {', '.join(missing)}"
            )

# Instantiate a singleton for convenient import elsewhere
settings = Settings()
