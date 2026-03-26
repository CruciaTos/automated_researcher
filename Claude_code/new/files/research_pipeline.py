"""
app/pipeline/research_pipeline.py — Pipeline entry point.

Thin dispatcher that selects the correct pipeline mode and hands off.
Kept here for backward compatibility with research_worker.py.
"""
import logging
from typing import Optional

from backend.app.pipeline.pipeline_factory import get_pipeline

logger = logging.getLogger(__name__)


def run_research_pipeline(
    job_id: int,
    topic: str,
    depth_minutes: int = 25,
    model_override: Optional[str] = None,
) -> None:
    """
    Select and run the appropriate research pipeline.

    Args:
        job_id:         ResearchJob primary key.
        topic:          Research topic string.
        depth_minutes:  Controls mode selection (≤10 basic, ≤30 standard, >30 deep).
        model_override: Ollama model to use (None = server default OLLAMA_MODEL).
    """
    pipeline = get_pipeline(depth_minutes, model_override=model_override)
    logger.info(
        "Dispatching job_id=%d to [%s] pipeline "
        "(depth=%d min, model=%s)",
        job_id,
        pipeline.mode_name,
        depth_minutes,
        pipeline.llm.model_name(),
    )
    pipeline.run(job_id, topic)
