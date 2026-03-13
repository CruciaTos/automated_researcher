from typing import Dict, List

import requests

WIKIPEDIA_API_URL = "https://en.wikipedia.org/w/api.php"


def _search_pages(topic: str, limit: int = 5) -> List[Dict[str, str]]:
    response = requests.get(
        WIKIPEDIA_API_URL,
        params={
            "action": "query",
            "format": "json",
            "list": "search",
            "srsearch": topic,
            "srlimit": limit,
        },
        timeout=10,
    )
    response.raise_for_status()
    data = response.json()
    return data.get("query", {}).get("search", [])


def _fetch_summary(page_title: str) -> Dict[str, str]:
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
        timeout=10,
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


def search_wikipedia(topic: str) -> List[Dict[str, str]]:
    """Search Wikipedia and return summaries for the top results."""
    results = []
    for result in _search_pages(topic):
        title = result.get("title")
        if not title:
            continue
        results.append(_fetch_summary(title))
    return results