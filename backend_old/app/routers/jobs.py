from typing import List

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ..llm.ollama_client import generate
from ..models.base import get_db
from ..models.chunk import Chunk
from ..models.document import Document
from ..models.research_job import ResearchJob
from ..schemas.research_job import JobCreate, JobResponse
from ..workers.research_worker import process_research_job


router = APIRouter(prefix="/jobs", tags=["jobs"])


class JobChatRequest(BaseModel):
    question: str


@router.post("", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def create_job(
    payload: JobCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
) -> JobResponse:
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
    return job


@router.get("/{job_id}", response_model=JobResponse)
def get_job(job_id: int, db: Session = Depends(get_db)) -> JobResponse:
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")
    return job


@router.get("/{job_id}/report")
def get_job_report(job_id: int, db: Session = Depends(get_db)):
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    return {
        "job_id": job.id,
        "topic": job.topic,
        "report": job.result_report,
        "status": job.status,
    }


@router.get("/{job_id}/sources")
def get_job_sources(job_id: int, db: Session = Depends(get_db)):
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()

    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

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
                "id": document.id,
                "title": document.title,
                "url": document.url,
                "snippet": (document.content or "")[:240],
                "source_type": document.source_type,
            }
            for document in documents
        ],
    }


@router.get("", response_model=List[JobResponse])
def list_jobs(db: Session = Depends(get_db)) -> List[JobResponse]:
    return db.query(ResearchJob).order_by(ResearchJob.id).all()


@router.post("/{job_id}/chat")
def chat_with_job(
    job_id: int,
    payload: JobChatRequest,
    db: Session = Depends(get_db),
) -> dict:
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found")

    chunks = (
        db.query(Chunk)
        .join(Document, Chunk.document_id == Document.id)
        .filter(Document.job_id == job_id)
        .limit(5)
        .all()
    )

    context = "\n\n".join(chunk.text for chunk in chunks)
    prompt = (
        "You are a research assistant. Use the context below to answer the question.\n\n"
        f"Context:\n{context}\n\n"
        f"Question: {payload.question}\n\nAnswer:"
    )

    answer = generate(prompt)
    return {"answer": answer}