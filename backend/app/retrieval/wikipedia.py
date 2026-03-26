"""
app/retrieval/wikipedia.py — Wikipedia search and summary retrieval.
"""

import logging
from typing import Dict, List

import requests

logger = logging.getLogger(__name__)

WIKIPEDIA_API_URL = "https://en.wikipedia.org/w/api.php"
_TIMEOUT = 10


def _search_pages(topic: str, limit: int = 5) -> List[Dict[str, str]]:
    """Return a list of raw search result dicts from the Wikipedia search API."""
    response = requests.get(
        WIKIPEDIA_API_URL,
        params={
            "action": "query",
            "format": "json",
            "list": "search",
            "srsearch": topic,
            "srlimit": limit,
        },
        timeout=_TIMEOUT,
    )
    response.raise_for_status()
    data = response.json()
    return data.get("query", {}).get("search", [])


def _fetch_summary(page_title: str) -> Dict[str, str]:
    """Fetch the intro extract and canonical URL for a single Wikipedia page."""
    response = requests.get(
        WIKIPEDIA_API_URL,
        params={
            "action": "query",
            "format": "json",
            "prop": "extracts|info",
            "exintro": True,
            "explaintext": True,
            "titles": page_title,
            "inprop": "url",
            "redirects": 1,
        },
        timeout=_TIMEOUT,
    )
    response.raise_for_status()
    pages = response.json().get("query", {}).get("pages", {})
    page = next(iter(pages.values()), {})
    return {
        "title": page.get("title", page_title),
        "url": page.get("fullurl", ""),
        "summary": page.get("extract", ""),
        "source": "wikipedia",
    }


def search_wikipedia(topic: str, limit: int = 5) -> List[Dict[str, str]]:
    """
    Search Wikipedia and return intro summaries for the top results.

    Args:
        topic: Search query string.
        limit: Maximum number of pages to fetch (default 5).

    Returns:
        List of dicts with keys: title, url, summary, source.
        Empty list on total failure (errors are logged, not raised).
    """
    results: List[Dict[str, str]] = []
    search_hits = _search_pages(topic, limit=limit)

    for hit in search_hits:
        title = hit.get("title")
        if not title:
            continue
        try:
            summary = _fetch_summary(title)
            results.append(summary)
        except Exception:
            logger.exception("Failed to fetch Wikipedia summary for %r", title)

    logger.debug("Wikipedia: %d summaries fetched for %r", len(results), topic)
    return results
