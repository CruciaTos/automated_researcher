"""
app/pipeline/research_pipeline.py — Pipeline entry point.

This module is now a thin dispatcher. All logic lives in the mode-specific
pipeline classes. Kept here for backward compatibility with research_worker.py.
"""
import logging
from backend.app.pipeline.pipeline_factory import get_pipeline

logger = logging.getLogger(__name__)


def run_research_pipeline(job_id: int, topic: str, depth_minutes: int = 25) -> None:
    """
    Select and run the appropriate research pipeline.

    Args:
        job_id:        ResearchJob primary key.
        topic:         Research topic string.
        depth_minutes: Controls mode selection (5 → basic, 25 → standard, 40 → deep).
    """
    pipeline = get_pipeline(depth_minutes)
    logger.info(
        "Dispatching job_id=%d to [%s] pipeline (depth=%d min)",
        job_id, pipeline.mode_name, depth_minutes,
    )
    pipeline.run(job_id, topic)