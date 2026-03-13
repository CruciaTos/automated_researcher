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

from app.pipeline.research_pipeline import run_research_pipeline

logger = logging.getLogger(__name__)

# max_workers=1 serialises jobs — safe for SQLite; increase for PostgreSQL.
_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="pipeline")


def process_research_job(job_id: int) -> None:
    """
    Entry point called by FastAPI `BackgroundTasks`.

    Submits the pipeline to the thread-pool executor so it runs off the
    event loop. The topic is fetched from the database inside the worker
    so that this function's signature matches FastAPI's expectation for
    background task callables (only serialisable scalar arguments).

    Args:
        job_id: Primary key of the ResearchJob to process.
    """
    logger.info("Scheduling pipeline for job_id=%d", job_id)
    topic = _fetch_topic(job_id)
    if topic is None:
        logger.error("job_id=%d not found — cannot start pipeline", job_id)
        return

    future = _executor.submit(_run, job_id, topic)
    future.add_done_callback(_on_done)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

def _run(job_id: int, topic: str) -> None:
    """Thread target — wraps the pipeline with top-level exception logging."""
    try:
        run_research_pipeline(job_id=job_id, topic=topic)
    except Exception:
        # Pipeline already marks the job as 'failed'; we just log here.
        logger.exception("Pipeline raised an unhandled exception (job_id=%d)", job_id)


def _on_done(future) -> None:
    """Future callback — surfaces unexpected executor errors."""
    exc = future.exception()
    if exc:
        logger.error("Executor future raised: %s", exc)


def _fetch_topic(job_id: int) -> str | None:
    """Retrieve the topic string for a job from the database."""
    from app.models.base import SessionLocal
    from app.models.research_job import ResearchJob

    db = SessionLocal()
    try:
        job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
        return job.topic if job else None
    finally:
        db.close()
