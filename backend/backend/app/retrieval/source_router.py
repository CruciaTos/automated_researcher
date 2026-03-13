"""
app/retrieval/source_router.py — Aggregates sources from all configured backends.
"""

import logging
from typing import List

from app.config import settings
from app.retrieval.arxiv import search_arxiv
from app.retrieval.wikipedia import search_wikipedia

logger = logging.getLogger(__name__)


def retrieve_sources(topic: str) -> List[dict]:
    """
    Fetch sources from all configured retrieval backends and return a
    deduplicated, capped list.

    Current backends (in priority order):
      1. Wikipedia — encyclopaedic overview
      2. arXiv     — academic papers

    Args:
        topic: The research topic string.

    Returns:
        A list of source dicts, each containing at minimum:
          title, url (or pdf_url), summary, source
        Capped at ``settings.max_sources`` entries.
    """
    sources: List[dict] = []

    try:
        wiki_results = search_wikipedia(topic)
        logger.info("Wikipedia returned %d results for %r", len(wiki_results), topic)
        sources.extend(wiki_results)
    except Exception:
        logger.exception("Wikipedia retrieval failed for topic %r", topic)

    try:
        arxiv_results = search_arxiv(topic)
        logger.info("arXiv returned %d results for %r", len(arxiv_results), topic)
        sources.extend(arxiv_results)
    except Exception:
        logger.exception("arXiv retrieval failed for topic %r", topic)

    # Deduplicate by URL (keep first occurrence)
    seen: set = set()
    unique: List[dict] = []
    for source in sources:
        url = source.get("url") or source.get("pdf_url", "")
        if url and url not in seen:
            seen.add(url)
            unique.append(source)
        elif not url:
            unique.append(source)  # keep sources with no URL rather than silently drop

    capped = unique[: settings.max_sources]
    logger.info(
        "retrieve_sources: %d total → %d unique → %d returned (cap=%d)",
        len(sources),
        len(unique),
        len(capped),
        settings.max_sources,
    )
    return capped
