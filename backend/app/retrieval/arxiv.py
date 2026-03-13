from typing import Dict, List
from xml.etree import ElementTree

import requests

ARXIV_API_URL = "http://export.arxiv.org/api/query"


def _get_text(element: ElementTree.Element, tag: str, namespace: dict) -> str:
    child = element.find(tag, namespace)
    return child.text.strip() if child is not None and child.text else ""


def _get_authors(entry: ElementTree.Element, namespace: dict) -> List[str]:
    return [
        author.findtext("atom:name", default="", namespaces=namespace).strip()
        for author in entry.findall("atom:author", namespace)
    ]


def _get_pdf_url(entry: ElementTree.Element, namespace: dict) -> str:
    for link in entry.findall("atom:link", namespace):
        if link.attrib.get("title") == "pdf":
            return link.attrib.get("href", "")
    return ""


def search_arxiv(topic: str) -> List[Dict[str, object]]:
    """Search arXiv and return up to 5 papers."""
    response = requests.get(
        ARXIV_API_URL,
        params={
            "search_query": f"all:{topic}",
            "start": 0,
            "max_results": 5,
        },
        timeout=10,
    )
    response.raise_for_status()

    root = ElementTree.fromstring(response.text)
    namespace = {"atom": "http://www.w3.org/2005/Atom"}
    entries = root.findall("atom:entry", namespace)

    results: List[Dict[str, object]] = []
    for entry in entries:
        results.append(
            {
                "title": _get_text(entry, "atom:title", namespace),
                "authors": _get_authors(entry, namespace),
                "summary": _get_text(entry, "atom:summary", namespace),
                "pdf_url": _get_pdf_url(entry, namespace),
                "source": "arxiv",
            }
        )
    return results