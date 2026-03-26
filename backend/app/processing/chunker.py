"""
app/processing/chunker.py — Text chunking utilities.

Splits long documents into overlapping fixed-size character chunks suitable
for embedding and vector search.
"""

import logging
from typing import List

logger = logging.getLogger(__name__)


def chunk_text(
    text: str,
    chunk_size: int = 500,
    overlap: int = 100,
) -> List[str]:
    """
    Split `text` into overlapping fixed-size character chunks.

    Args:
        text:       The input string to chunk.
        chunk_size: Maximum number of characters per chunk (default 500).
        overlap:    Number of characters shared between consecutive chunks
                    (default 100). Must be < chunk_size.

    Returns:
        A list of non-empty string chunks. Returns an empty list if
        `text` is empty or whitespace-only.

    Raises:
        ValueError: If `chunk_size` <= 0, `overlap` < 0, or
                    `overlap` >= `chunk_size`.

    Example::

        chunks = chunk_text("Hello world " * 100, chunk_size=50, overlap=10)
    """
    if chunk_size <= 0:
        raise ValueError(f"chunk_size must be > 0, got {chunk_size}")
    if overlap < 0:
        raise ValueError(f"overlap must be >= 0, got {overlap}")
    if overlap >= chunk_size:
        raise ValueError(
            f"overlap ({overlap}) must be < chunk_size ({chunk_size})"
        )

    text = text.strip()
    if not text:
        return []

    chunks: List[str] = []
    start = 0
    length = len(text)

    while start < length:
        end = min(start + chunk_size, length)
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        if end == length:
            break
        start = end - overlap

    logger.debug(
        "chunk_text: input=%d chars → %d chunks (size=%d overlap=%d)",
        length,
        len(chunks),
        chunk_size,
        overlap,
    )
    return chunks
