"""
app/models/research_job.py — SQLAlchemy ORM model for research jobs.
"""

from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, String, Text
from sqlalchemy.sql import func

from backend.app.models.base import Base


class ResearchJob(Base):
    __tablename__ = "research_jobs"

    id = Column(Integer, primary_key=True, index=True)
    topic = Column(String(512), nullable=False)
    depth_minutes = Column(Integer, default=5, nullable=False)
    status = Column(String(50), default="queued", nullable=False)
    progress = Column(Integer, default=0, nullable=False)
    result_report = Column(Text, nullable=True)

    # User-selected Ollama model for this job (None = use server default)
    model_override = Column(String(200), nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        onupdate=func.now(),
        nullable=True,
    )
