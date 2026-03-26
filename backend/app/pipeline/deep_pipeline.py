"""
app/pipeline/deep_pipeline.py — Level 3: Verified research engine.

Priority: Accuracy + Depth > Speed
Sources: 5–15 (Wikipedia + arXiv, credibility-ranked, diversity-enforced)
Processing:
  - Cross-source claim verification
  - Contradiction detection and resolution
  - Information fusion via multi-step LLM reasoning
Output: 800–1500+ words, research paper format, citations required
"""
import logging
from typing import Any, Dict, List, Tuple

from backend.app.llm.llm_provider import LLMProvider
from backend.app.pipeline.base_pipeline import BaseResearchPipeline
from backend.app.retrieval.arxiv import search_arxiv
from backend.app.retrieval.wikipedia import search_wikipedia

logger = logging.getLogger(__name__)

# Credibility weights — academic papers score higher than encyclopaedia
_CRED_ARXIV = 0.90
_CRED_WIKI = 0.70


class DeepResearchPipeline(BaseResearchPipeline):

    def __init__(self, llm: LLMProvider):
        super().__init__(llm)

    @property
    def mode_name(self) -> str:
        return "deep"

    @property
    def max_sources(self) -> int:
        return 15

    # ── Retrieval ─────────────────────────────────────────────────────────

    def retrieve_sources(self, topic: str) -> List[Dict[str, Any]]:
        """
        Multi-backend retrieval with credibility scoring and deduplication.
        Ensures source diversity: both academic and encyclopaedic coverage.
        """
        sources: List[Dict[str, Any]] = []

        try:
            wiki_results = search_wikipedia(topic, limit=5)
            for s in wiki_results:
                s["credibility"] = _CRED_WIKI
            sources.extend(wiki_results)
            logger.debug("[deep] Wikipedia: %d results", len(wiki_results))
        except Exception:
            logger.exception("[deep] Wikipedia retrieval failed")

        try:
            arxiv_results = search_arxiv(topic, max_results=10)
            for s in arxiv_results:
                s["credibility"] = _CRED_ARXIV
            sources.extend(arxiv_results)
            logger.debug("[deep] arXiv: %d results", len(arxiv_results))
        except Exception:
            logger.exception("[deep] arXiv retrieval failed")

        # Sort by credibility (highest first), then deduplicate
        sources.sort(key=lambda s: s.get("credibility", 0.5), reverse=True)
        unique = _deduplicate(sources)

        logger.info("[deep] %d unique sources after dedup", len(unique))
        return unique[:self.max_sources]

    # ── Verification layer ────────────────────────────────────────────────

    def _verify_claims(self, sources: List[Dict[str, Any]], topic: str) -> str:
        """
        Ask the LLM to extract key factual claims and identify which sources
        support each. Claims supported by 2+ sources are marked as verified.
        """
        # Cap to 8 sources for the extraction prompt to avoid token overflow
        compact = "\n\n".join(
            f"[{i+1}] {s.get('title', '')} ({s.get('source', '')})\n"
            f"{(s.get('summary') or '')[:500]}"
            for i, s in enumerate(sources[:8])
        )
        prompt = (
            f"Extract 5–8 key factual claims about '{topic}' from the sources.\n"
            "For each claim, list which source numbers support it.\n\n"
            "Strict output format (one per line):\n"
            "CLAIM: <the claim> | SOURCES: [1,3]\n\n"
            f"Sources:\n{compact}\n\n"
            "Claims:"
        )
        raw = self.llm.generate(prompt)

        verified_lines = []
        for line in raw.splitlines():
            line = line.strip()
            if "CLAIM:" not in line or "SOURCES:" not in line:
                continue
            try:
                claim_part, src_part = line.split("SOURCES:", 1)
                claim = claim_part.replace("CLAIM:", "").strip(" |-")
                src_nums = [
                    int(x.strip())
                    for x in src_part.strip().strip("[]").split(",")
                    if x.strip().isdigit()
                ]
                badge = "✓ Verified" if len(src_nums) >= 2 else "⚠ Single source"
                verified_lines.append(f"- [{badge}] {claim} (sources: {src_nums})")
            except Exception:
                continue

        if not verified_lines:
            return "Claim verification produced no structured output."
        return "\n".join(verified_lines)

    def _detect_contradictions(self, sources: List[Dict[str, Any]], topic: str) -> str:
        """
        Ask the LLM to identify conflicting claims across sources
        and propose resolution via majority agreement or credibility weighting.
        """
        compact = "\n\n".join(
            f"[{i+1}] {s.get('title', '')} "
            f"(credibility={s.get('credibility', 0.5):.1f})\n"
            f"{(s.get('summary') or '')[:400]}"
            for i, s in enumerate(sources[:8])
        )
        prompt = (
            f"Identify contradictions or conflicting claims across these sources about '{topic}'.\n"
            "For each conflict:\n"
            "  1. State what the disagreement is\n"
            "  2. Note which sources conflict\n"
            "  3. Suggest a resolution (majority agreement or higher credibility wins)\n\n"
            "If no meaningful contradictions exist, state: 'No significant contradictions found.'\n\n"
            f"Sources:\n{compact}\n\n"
            "Contradiction analysis:"
        )
        return self.llm.generate(prompt)

    # ── Report generation ─────────────────────────────────────────────────

    def generate_report(
        self,
        topic: str,
        sources: List[Dict[str, Any]],
        context: str,
    ) -> str:
        """
        Multi-step generation:
          1. Verify claims across sources
          2. Detect contradictions
          3. Generate research paper with full reasoning
        """
        logger.info("[deep] Step 1/3 — verifying claims")
        verified_claims = self._verify_claims(sources, topic)

        logger.info("[deep] Step 2/3 — detecting contradictions")
        contradiction_analysis = self._detect_contradictions(sources, topic)

        citation_block = "\n".join(
            f"[{i+1}] {s.get('title', 'Unknown')} — "
            f"{s.get('url') or s.get('pdf_url', 'N/A')} "
            f"(credibility: {s.get('credibility', 0.5):.1f})"
            for i, s in enumerate(sources)
        )

        logger.info("[deep] Step 3/3 — generating full report")
        prompt = (
            f"Write a comprehensive research paper (900–1400 words) on: {topic}\n\n"
            f"=== VERIFIED CLAIMS (use these as your factual backbone) ===\n"
            f"{verified_claims}\n\n"
            f"=== CONTRADICTION ANALYSIS (address these in Discussion) ===\n"
            f"{contradiction_analysis}\n\n"
            f"=== SOURCE MATERIAL ===\n{context}\n\n"
            f"=== CITATION LIST ===\n{citation_block}\n\n"
            "MANDATORY STRUCTURE (use # for each heading):\n"
            "# [Descriptive Title]\n"
            "## Abstract\n"
            "## Introduction\n"
            "## [Main Section 1]\n"
            "## [Main Section 2]\n"
            "## [Main Section 3 if needed]\n"
            "## Analysis & Discussion\n"
            "## Conclusion\n"
            "## References\n\n"
            "STRICT RULES:\n"
            "- Cite sources inline using [N] notation after each major claim\n"
            "- Mark claims with only one source as (unverified)\n"
            "- In Discussion: explicitly address the contradictions identified above\n"
            "- Explain WHY and HOW, not just WHAT\n"
            "- Use academic tone throughout\n"
            "- Full prose paragraphs — no bullet points in the main body\n"
            "- References section must list all cited sources\n\n"
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