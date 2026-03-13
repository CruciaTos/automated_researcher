"""Pydantic schemas for research jobs."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class JobCreate(BaseModel):
    """Payload used to create a research job."""

    topic: str
    depth_minutes: int


class JobResponse(BaseModel):
    """Response schema for research job details."""

    id: int
    topic: str
    depth_minutes: int
    status: str
    progress: int
    result_report: Optional[str]
    created_at: datetime

    class Config:
        orm_mode = True