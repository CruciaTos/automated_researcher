"""
app/retrieval/arxiv.py — arXiv paper search via the Atom API.
"""

import logging
from typing import Dict, List
from xml.etree import ElementTree

import requests

logger = logging.getLogger(__name__)

ARXIV_API_URL = "http://export.arxiv.org/api/query"
_NAMESPACE = {"atom": "http://www.w3.org/2005/Atom"}
_TIMEOUT = 10


def _get_text(element: ElementTree.Element, tag: str) -> str:
    child = element.find(tag, _NAMESPACE)
    return child.text.strip() if child is not None and child.text else ""


def _get_authors(entry: ElementTree.Element) -> List[str]:
    return [
        (author.findtext("atom:name", default="", namespaces=_NAMESPACE) or "").strip()
        for author in entry.findall("atom:author", _NAMESPACE)
    ]


def _get_pdf_url(entry: ElementTree.Element) -> str:
    for link in entry.findall("atom:link", _NAMESPACE):
        if link.attrib.get("title") == "pdf":
            return link.attrib.get("href", "")
    return ""


def _get_abstract_url(entry: ElementTree.Element) -> str:
    """Return the HTML abstract page URL (used as the canonical URL)."""
    for link in entry.findall("atom:link", _NAMESPACE):
        if link.attrib.get("rel") == "alternate":
            return link.attrib.get("href", "")
    return _get_text(entry, "atom:id")


def search_arxiv(topic: str, max_results: int = 5) -> List[Dict[str, object]]:
    """
    Search arXiv and return up to `max_results` paper metadata dicts.

    Args:
        topic:       Search query string.
        max_results: Maximum number of papers to return (default 5).

    Returns:
        List of dicts with keys:
          title, authors, summary, url, pdf_url, source
    """
    response = requests.get(
        ARXIV_API_URL,
        params={
            "search_query": f"all:{topic}",
            "start": 0,
            "max_results": max_results,
        },
        timeout=_TIMEOUT,
    )
    response.raise_for_status()

    root = ElementTree.fromstring(response.text)
    entries = root.findall("atom:entry", _NAMESPACE)

    results: List[Dict[str, object]] = []
    for entry in entries:
        results.append(
            {
                "title": _get_text(entry, "atom:title"),
                "authors": _get_authors(entry),
                "summary": _get_text(entry, "atom:summary"),
                "url": _get_abstract_url(entry),
                "pdf_url": _get_pdf_url(entry),
                "source": "arxiv",
            }
        )

    logger.debug("arXiv: %d results for %r", len(results), topic)
    return results
