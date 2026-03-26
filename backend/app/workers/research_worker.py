"""
app/workers/research_worker.py — Background worker for research jobs.

The pipeline (`run_research_pipeline`) is synchronous and CPU/IO-bound.
FastAPI's `BackgroundTasks` can schedule both sync and async callables;
we use a `ThreadPoolExecutor` with a single worker to:

  1. Avoid blocking the event loop (asyncio would stall on the long LLM calls).
  2. Serialise pipeline runs to prevent concurrent SQLite write conflicts.

Switch to a proper task queue (Celery, ARQ, etc.) if you need parallelism.
"""

import logging
from concurrent.futures import ThreadPoolExecutor

from backend.app.pipeline.research_pipeline import run_research_pipeline

logger = logging.getLogger(__name__)

# max_workers=1 serialises jobs — safe for SQLite; increase for PostgreSQL.
_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="pipeline")


def process_research_job(job_id: int) -> None:
    logger.info("Scheduling pipeline for job_id=%d", job_id)
    job_data = _fetch_job_data(job_id)
    if job_data is None:
        logger.error("job_id=%d not found — cannot start pipeline", job_id)
        return

    topic, depth_minutes = job_data
    future = _executor.submit(_run, job_id, topic, depth_minutes)
    future.add_done_callback(_on_done)


def _run(job_id: int, topic: str, depth_minutes: int) -> None:
    try:
        run_research_pipeline(job_id=job_id, topic=topic, depth_minutes=depth_minutes)
    except Exception:
        logger.exception("Pipeline raised unhandled exception (job_id=%d)", job_id)


def _fetch_job_data(job_id: int):
    """Returns (topic, depth_minutes) tuple or None if job not found."""
    from backend.app.models.base import SessionLocal
    from backend.app.models.research_job import ResearchJob

    db = SessionLocal()
    try:
        job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
        if not job:
            return None
        return job.topic, job.depth_minutes
    finally:
        db.close()