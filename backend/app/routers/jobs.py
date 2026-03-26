"""
app/routers/jobs.py — Research job CRUD and interaction endpoints.
"""

import logging
from typing import List

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from backend.app.llm.ollama_client import generate
from backend.app.models.base import get_db
from backend.app.models.chunk import Chunk
from backend.app.models.document import Document
from backend.app.models.research_job import ResearchJob
from backend.app.schemas.research_job import JobCreate, JobResponse
from backend.app.workers.research_worker import process_research_job

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/jobs", tags=["jobs"])


class JobChatRequest(BaseModel):
    question: str


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------

@router.post(
    "",
    response_model=JobResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Submit a new research job",
)
def create_job(
    payload: JobCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
) -> JobResponse:
    """
    Create a new research job and immediately enqueue it for processing.

    The job starts in `queued` status. Poll `GET /jobs/{job_id}` to track
    progress, or `GET /jobs/{job_id}/report` when status is `completed`.
    """
    job = ResearchJob(
        topic=payload.topic,
        depth_minutes=payload.depth_minutes,
        status="queued",
        progress=0,
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    background_tasks.add_task(process_research_job, job.id)
    logger.info("Created job id=%d topic=%r", job.id, job.topic)
    return job


# ---------------------------------------------------------------------------
# List / Read
# ---------------------------------------------------------------------------

@router.get(
    "",
    response_model=List[JobResponse],
    summary="List all research jobs",
)
def list_jobs(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
) -> List[JobResponse]:
    """Return a paginated list of all research jobs, oldest first."""
    return (
        db.query(ResearchJob)
        .order_by(ResearchJob.id)
        .offset(skip)
        .limit(limit)
        .all()
    )


@router.get(
    "/{job_id}",
    response_model=JobResponse,
    summary="Get job status and metadata",
)
def get_job(job_id: int, db: Session = Depends(get_db)) -> JobResponse:
    """Retrieve status, progress, and metadata for a single job."""
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
        )
    return job


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

@router.get("/{job_id}/report", summary="Get the generated research report")
def get_job_report(job_id: int, db: Session = Depends(get_db)):
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    # Return source documents as citation objects for the frontend
    documents = (
        db.query(Document)
        .filter(Document.job_id == job_id)
        .order_by(Document.id)
        .all()
    )
    citations = [
        {"id": i + 1, "title": doc.title, "url": doc.url or ""}
        for i, doc in enumerate(documents)
        if doc.url  # skip documents without a resolvable URL
    ]

    return {
        "job_id": job.id,
        "topic": job.topic,
        "status": job.status,
        "report": job.result_report,
        "citations": citations,
    }


# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------

@router.get("/{job_id}/sources", summary="List sources retrieved for a job")
def get_job_sources(job_id: int, db: Session = Depends(get_db)):
    """Return all source documents retrieved during the pipeline's fetch stage."""
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
        )

    documents = (
        db.query(Document)
        .filter(Document.job_id == job_id)
        .order_by(Document.id)
        .all()
    )

    return {
        "job_id": job.id,
        "topic": job.topic,
        "sources": [
            {
                "id": doc.id,
                "title": doc.title,
                "url": doc.url,
                "snippet": (doc.content or "")[:240],
                "source_type": doc.source_type,
            }
            for doc in documents
        ],
    }


# ---------------------------------------------------------------------------
# Chat (RAG)
# ---------------------------------------------------------------------------

@router.post("/{job_id}/chat", summary="Ask a question about a completed job")
def chat_with_job(
    job_id: int,
    payload: JobChatRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Answer a question using the chunks stored for this job as context.

    NOTE: Currently retrieves the first 5 chunks by insertion order.
    For semantic retrieval, load the FAISS index for this job and query
    it with the embedded question before calling the LLM.
    """
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if not job:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Job not found"
        )

    if job.status != "completed":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Job is not completed yet (status={job.status!r}). "
                   "Chat is only available after the pipeline finishes.",
        )

    chunks = (
        db.query(Chunk)
        .join(Document, Chunk.document_id == Document.id)
        .filter(Document.job_id == job_id)
        .order_by(Chunk.id)
        .limit(5)
        .all()
    )

    if not chunks:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No chunks found for this job. The pipeline may not have "
                   "produced any content.",
        )

    context = "\n\n".join(chunk.text for chunk in chunks)
    prompt = (
        "You are a research assistant. Use ONLY the context below to answer "
        "the question. If the answer cannot be found in the context, say so.\n\n"
        f"Context:\n{context}\n\n"
        f"Question: {payload.question}\n\nAnswer:"
    )

    logger.info("Chat request — job_id=%d question_len=%d", job_id, len(payload.question))
    answer = generate(prompt)
    return {"job_id": job_id, "question": payload.question, "answer": answer}
