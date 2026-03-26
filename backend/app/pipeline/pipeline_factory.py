"""
app/pipeline/pipeline_factory.py — Mode selector.

Maps depth_minutes → pipeline class.
Frontend sends: 5 (basic), 25 (standard), 40 (deep).
"""
import logging
from backend.app.llm.llm_provider import get_default_provider
from backend.app.pipeline.base_pipeline import BaseResearchPipeline
from backend.app.pipeline.basic_pipeline import BasicResearchPipeline
from backend.app.pipeline.deep_pipeline import DeepResearchPipeline
from backend.app.pipeline.standard_pipeline import StandardResearchPipeline

logger = logging.getLogger(__name__)

_BASIC_THRESHOLD = 10    # depth_minutes ≤ 10  → basic
_STANDARD_THRESHOLD = 30 # depth_minutes ≤ 30  → standard
                         # depth_minutes  > 30  → deep


def get_pipeline(depth_minutes: int) -> BaseResearchPipeline:
    """
    Returns the appropriate pipeline instance for the given depth.

    depth ≤ 10   → BasicResearchPipeline    (1–3 sources, fast summary)
    depth ≤ 30   → StandardResearchPipeline (3–7 sources, structured)
    depth  > 30  → DeepResearchPipeline     (5–15 sources, verified)
    """
    llm = get_default_provider()

    if depth_minutes <= _BASIC_THRESHOLD:
        logger.info("Mode: BASIC (depth_minutes=%d)", depth_minutes)
        return BasicResearchPipeline(llm)
    elif depth_minutes <= _STANDARD_THRESHOLD:
        logger.info("Mode: STANDARD (depth_minutes=%d)", depth_minutes)
        return StandardResearchPipeline(llm)
    else:
        logger.info("Mode: DEEP (depth_minutes=%d)", depth_minutes)
        return DeepResearchPipeline(llm)