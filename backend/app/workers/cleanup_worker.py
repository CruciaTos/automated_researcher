from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from ..models.base import SessionLocal
from ..models.research_job import ResearchJob


def delete_expired_jobs() -> int:
    """Delete research jobs older than 3 days. Returns count deleted."""
    cutoff = datetime.utcnow() - timedelta(days=3)
    db: Session = SessionLocal()
    try:
        expired_jobs = db.query(ResearchJob).filter(ResearchJob.created_at < cutoff)
        deleted = expired_jobs.count()
        expired_jobs.delete(synchronize_session=False)
        db.commit()
        return deleted
    finally:
        db.close()