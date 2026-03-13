"""
app/workers/cleanup_worker.py — Periodic job cleanup worker.

Intended to be called from a scheduled task (cron, APScheduler, etc.).
"""

import logging
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.config import settings
from app.models.base import SessionLocal
from app.models.research_job import ResearchJob

logger = logging.getLogger(__name__)


def delete_expired_jobs(max_age_days: int | None = None) -> int:
    """
    Delete research jobs older than `max_age_days` days.

    Args:
        max_age_days: Age threshold in days. Defaults to
                      ``settings.job_expiry_days`` (env: JOB_EXPIRY_DAYS).

    Returns:
        Number of jobs deleted.

    Raises:
        sqlalchemy.exc.SQLAlchemyError: Re-raised after rollback if the
        DELETE or COMMIT fails.
    """
    age = max_age_days if max_age_days is not None else settings.job_expiry_days
    cutoff = datetime.utcnow() - timedelta(days=age)

    db: Session = SessionLocal()
    try:
        expired = db.query(ResearchJob).filter(ResearchJob.created_at < cutoff)
        count = expired.count()

        if count == 0:
            logger.info("Cleanup: no expired jobs found (cutoff=%s)", cutoff.isoformat())
            return 0

        expired.delete(synchronize_session=False)
        db.commit()
        logger.info(
            "Cleanup: deleted %d job(s) older than %d day(s) (cutoff=%s)",
            count,
            age,
            cutoff.isoformat(),
        )
        return count

    except Exception:
        db.rollback()
        logger.exception("Cleanup failed — transaction rolled back")
        raise

    finally:
        db.close()
