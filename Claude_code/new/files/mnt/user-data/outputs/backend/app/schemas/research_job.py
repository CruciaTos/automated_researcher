"""
app/schemas/research_job.py — Pydantic request / response schemas for research jobs.
"""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator


class JobCreate(BaseModel):
    """Payload used to create a new research job."""

    topic: str = Field(
        ...,
        min_length=3,
        max_length=512,
        description="The research topic to investigate.",
        examples=["quantum computing", "climate change mitigation strategies"],
    )
    depth_minutes: int = Field(
        default=5,
        ge=1,
        le=60,
        description=(
            "Intended research depth in minutes (1–60). "
            "Controls pipeline mode: ≤10 → basic, ≤30 → standard, >30 → deep."
        ),
    )
    model_override: Optional[str] = Field(
        default=None,
        max_length=200,
        description=(
            "Ollama model name to use for this job (e.g. 'llama3:8b'). "
            "If None the server default (OLLAMA_MODEL env var) is used."
        ),
    )

    @field_validator("topic")
    @classmethod
    def topic_not_blank(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("topic must not be blank")
        return v.strip()

    @field_validator("model_override")
    @classmethod
    def model_override_stripped(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            v = v.strip()
            return v if v else None
        return None


class JobResponse(BaseModel):
    """Response schema returned for research job reads."""

    id: int
    topic: str
    depth_minutes: int
    status: str = Field(
        description=(
            "Pipeline stage. One of: queued, retrieving_sources, "
            "fetching_documents, chunking_documents, embedding_documents, "
            "drafting_outline, writing_report, completed, failed."
        )
    )
    progress: int = Field(description="Completion percentage (0–100).")
    result_report: Optional[str] = Field(
        default=None,
        description="The generated research report. Non-null only when status=completed.",
    )
    model_override: Optional[str] = Field(
        default=None,
        description="Ollama model used for this job (None = server default).",
    )
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
