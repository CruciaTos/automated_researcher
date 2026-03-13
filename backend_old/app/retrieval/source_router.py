from typing import List

from .arxiv import search_arxiv
from .wikipedia import search_wikipedia


def retrieve_sources(topic: str) -> List[dict]:
    """Aggregate sources from configured retrieval backends."""
    sources: List[dict] = []
    sources.extend(search_wikipedia(topic))
    sources.extend(search_arxiv(topic))
    return sources[:10]