"""
app/embeddings/embedder.py — Sentence embedding via sentence-transformers.

Critical fix applied:
  The model name MUST be a full HuggingFace repo ID.
  "bge-small-en-v1.5" is NOT valid — use "BAAI/bge-small-en-v1.5".

The model is loaded once at module import time. This is intentional to
avoid reloading on every request, but it means startup is slower.
Override the model via the EMBEDDING_MODEL environment variable.
"""

import logging
from typing import List

from sentence_transformers import SentenceTransformer

from app.config import settings

logger = logging.getLogger(__name__)

logger.info("Loading embedding model: %s", settings.embedding_model)
_model = SentenceTransformer(settings.embedding_model)
logger.info("Embedding model ready.")


def embed_texts(texts: List[str]) -> List[List[float]]:
    """
    Generate embedding vectors for a list of plain-text strings.

    Args:
        texts: Non-empty list of strings to embed.

    Returns:
        A list of float lists, one per input string.
        Returns an empty list if `texts` is empty.

    Example::

        vectors = embed_texts(["quantum computing", "black holes"])
        # vectors[0] has length 384 (for BAAI/bge-small-en-v1.5)
    """
    if not texts:
        logger.debug("embed_texts called with empty list — returning []")
        return []

    logger.debug("Embedding %d text(s)", len(texts))
    embeddings = _model.encode(texts, convert_to_numpy=True, show_progress_bar=False)
    return embeddings.tolist()
