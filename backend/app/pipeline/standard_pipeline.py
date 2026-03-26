"""
app/pipeline/standard_pipeline.py — Level 2: Structured synthesis.

Priority: Balance between speed and quality
Sources: 3–7 (Wikipedia + arXiv, deduplicated)
Output:  300–800 words, structured with headings
"""
import logging
from typing import Any, Dict, List

from backend.app.llm.llm_provider import LLMProvider
from backend.app.pipeline.base_pipeline import BaseResearchPipeline
from backend.app.retrieval.arxiv import search_arxiv
from backend.app.retrieval.wikipedia import search_wikipedia

logger = logging.getLogger(__name__)


class StandardResearchPipeline(BaseResearchPipeline):

    def __init__(self, llm: LLMProvider):
        super().__init__(llm)

    @property
    def mode_name(self) -> str:
        return "standard"

    @property
    def max_sources(self) -> int:
        return 7

    def retrieve_sources(self, topic: str) -> List[Dict[str, Any]]:
        """Wikipedia + arXiv, basic deduplication."""
        sources: List[Dict[str, Any]] = []

        try:
            sources.extend(search_wikipedia(topic, limit=4))
        except Exception:
            logger.exception("[standard] Wikipedia failed for %r", topic)

        try:
            sources.extend(search_arxiv(topic, max_results=5))
        except Exception:
            logger.exception("[standard] arXiv failed for %r", topic)

        return _deduplicate(sources)[:self.max_sources]

    def generate_report(
        self,
        topic: str,
        sources: List[Dict[str, Any]],
        context: str,
    ) -> str:
        source_titles = "\n".join(
            f"  [{i+1}] {s.get('title', 'Unknown')}"
            for i, s in enumerate(sources)
        )
        prompt = (
            f"Write a well-structured 400–700 word research overview about: {topic}\n\n"
            f"Available sources:\n{source_titles}\n\n"
            f"Source content:\n\n{context}\n\n"
            "Requirements:\n"
            "- Use 3–5 section headings (prefix each with #)\n"
            "- Start with an Introduction section\n"
            "- End with a Conclusion section\n"
            "- Merge similar information from different sources\n"
            "- Organize ideas logically, not just by source order\n"
            "- Clear, informative prose — no bullet points\n"
            "- No inline citation numbers required\n\n"
            "Report:"
        )
        return self.llm.generate(prompt)


def _deduplicate(sources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    seen: set = set()
    out = []
    for src in sources:
        url = src.get("url") or src.get("pdf_url", "")
        if url not in seen:
            seen.add(url)
            out.append(src)
    return out