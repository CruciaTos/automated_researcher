"""
app/pipeline/basic_pipeline.py — Level 1: Fast retrieval.

Priority: Speed > Accuracy
Sources: 1–3 (Wikipedia only)
Output:  100–300 words, plain prose, no citations
"""
import logging
from typing import Any, Dict, List

from backend.app.llm.llm_provider import LLMProvider
from backend.app.pipeline.base_pipeline import BaseResearchPipeline
from backend.app.retrieval.wikipedia import search_wikipedia

logger = logging.getLogger(__name__)


class BasicResearchPipeline(BaseResearchPipeline):

    def __init__(self, llm: LLMProvider):
        super().__init__(llm)

    @property
    def mode_name(self) -> str:
        return "basic"

    @property
    def max_sources(self) -> int:
        return 3

    def retrieve_sources(self, topic: str) -> List[Dict[str, Any]]:
        """Wikipedia only — fastest path, no arXiv overhead."""
        try:
            results = search_wikipedia(topic, limit=self.max_sources)
            return results[:self.max_sources]
        except Exception:
            logger.exception("[basic] Wikipedia retrieval failed for %r", topic)
            return []

    def generate_report(
        self,
        topic: str,
        sources: List[Dict[str, Any]],
        context: str,
    ) -> str:
        prompt = (
            f"Write a concise 150–250 word factual summary about: {topic}\n\n"
            f"Source material:\n\n{context}\n\n"
            "Rules:\n"
            "- Plain prose paragraphs only, no headings\n"
            "- Cover only the most important facts\n"
            "- No citations or reference numbers\n"
            "- Be direct and clear\n\n"
            "Summary:"
        )
        return self.llm.generate(prompt)