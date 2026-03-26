"""
app/workers/research_worker.py — Background worker for research jobs.

Fixes applied vs original:
  1. _on_done was referenced but never defined → NameError at runtime. Fixed.
  2. model_override is now read from the job record and threaded through
     to run_research_pipeline so the user's chosen Ollama model is used.
"""

import logging
from concurrent.futures import Future, ThreadPoolExecutor
from typing import Optional, Tuple

from backend.app.pipeline.research_pipeline import run_research_pipeline

logger = logging.getLogger(__name__)

# max_workers=1 serialises jobs — safe for SQLite; increase for PostgreSQL.
_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="pipeline")


def process_research_job(job_id: int) -> None:
    """Schedule the research pipeline for `job_id` on the thread pool."""
    logger.info("Scheduling pipeline for job_id=%d", job_id)
    job_data = _fetch_job_data(job_id)
    if job_data is None:
        logger.error("job_id=%d not found — cannot start pipeline", job_id)
        return

    topic, depth_minutes, model_override = job_data
    future = _executor.submit(_run, job_id, topic, depth_minutes, model_override)
    future.add_done_callback(_on_done)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _run(
    job_id: int,
    topic: str,
    depth_minutes: int,
    model_override: Optional[str],
) -> None:
    """Execute the pipeline synchronously inside the thread pool worker."""
    try:
        run_research_pipeline(
            job_id=job_id,
            topic=topic,
            depth_minutes=depth_minutes,
            model_override=model_override,
        )
    except Exception:
        logger.exception("Pipeline raised unhandled exception (job_id=%d)", job_id)


def _on_done(future: Future) -> None:
    """
    Callback invoked by ThreadPoolExecutor when the pipeline thread finishes.
    Re-raises exceptions so they appear in logs rather than being silently swallowed.
    """
    try:
        future.result()
    except Exception:
        logger.exception("Pipeline thread completed with an unhandled exception")


def _fetch_job_data(job_id: int) -> Optional[Tuple[str, int, Optional[str]]]:
    """
    Fetch (topic, depth_minutes, model_override) for the given job_id.
    Returns None if the job does not exist.
    """
    from backend.app.models.base import SessionLocal
    from backend.app.models.research_job import ResearchJob

    db = SessionLocal()
    try:
        job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
        if not job:
            return None
        return job.topic, job.depth_minutes, job.model_override
    finally:
        db.close()
