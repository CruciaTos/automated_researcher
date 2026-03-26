"""
app/pipeline/pipeline_factory.py — Mode selector.

Maps depth_minutes → pipeline class.
Frontend sends: 5 (basic), 25 (standard), 40 (deep).
"""
import logging
from typing import Optional

from backend.app.llm.llm_provider import get_default_provider
from backend.app.pipeline.base_pipeline import BaseResearchPipeline
from backend.app.pipeline.basic_pipeline import BasicResearchPipeline
from backend.app.pipeline.deep_pipeline import DeepResearchPipeline
from backend.app.pipeline.standard_pipeline import StandardResearchPipeline

logger = logging.getLogger(__name__)

_BASIC_THRESHOLD = 10     # depth_minutes ≤ 10  → basic
_STANDARD_THRESHOLD = 30  # depth_minutes ≤ 30  → standard
                          # depth_minutes  > 30  → deep


def get_pipeline(
    depth_minutes: int,
    model_override: Optional[str] = None,
) -> BaseResearchPipeline:
    """
    Returns the appropriate pipeline instance for the given depth.

    Args:
        depth_minutes:  Controls pipeline complexity/source count.
        model_override: Specific Ollama model to use (None = server default).

    Routing:
        depth ≤ 10  → BasicResearchPipeline    (1–3 sources, fast summary)
        depth ≤ 30  → StandardResearchPipeline (3–7 sources, structured)
        depth  > 30 → DeepResearchPipeline     (5–15 sources, verified)
    """
    llm = get_default_provider(model_override=model_override)

    if depth_minutes <= _BASIC_THRESHOLD:
        logger.info("Mode: BASIC (depth=%d min, model=%s)", depth_minutes, llm.model_name())
        return BasicResearchPipeline(llm)
    elif depth_minutes <= _STANDARD_THRESHOLD:
        logger.info("Mode: STANDARD (depth=%d min, model=%s)", depth_minutes, llm.model_name())
        return StandardResearchPipeline(llm)
    else:
        logger.info("Mode: DEEP (depth=%d min, model=%s)", depth_minutes, llm.model_name())
        return DeepResearchPipeline(llm)
