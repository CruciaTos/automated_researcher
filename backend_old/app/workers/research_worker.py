import asyncio

from sqlalchemy.orm import Session

from ..models.base import SessionLocal
from ..models.research_job import ResearchJob


async def process_research_job(job_id: int) -> None:
    """Placeholder async pipeline for processing a research job."""

    db: Session = SessionLocal()
    try:
        job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
        if not job:
            return

        stages = [
            ("retrieving_sources", 10),
            ("fetching_documents", 40),
            ("drafting_report", 80),
            ("completed", 100),
        ]

        for status, progress in stages:
            job.status = status
            job.progress = progress
            db.add(job)
            db.commit()
            db.refresh(job)
            await asyncio.sleep(1)
    finally:
        db.close()