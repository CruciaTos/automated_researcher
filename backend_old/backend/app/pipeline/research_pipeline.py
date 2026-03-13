"""
app/pipeline/research_pipeline.py — Research pipeline orchestrator.

Stages
------
1. retrieve_sources     — Wikipedia + arXiv
2. fetch_documents      — persist Document rows to DB
3. chunk_documents      — split text into overlapping chunks + persist Chunk rows
4. embed_and_index      — generate embeddings, build FAISS index, save to disk
5. generate_outline     — LLM call: structured outline
6. write_report         — LLM call: full research report
"""

import logging
import os
from typing import List

import faiss

from app.config import settings
from app.embeddings.embedder import embed_texts
from app.llm.ollama_client import generate
from app.models.base import SessionLocal
from app.models.chunk import Chunk
from app.models.document import Document
from app.models.research_job import ResearchJob
from app.processing.chunker import chunk_text
from app.retrieval.source_router import retrieve_sources
from app.vector_store.faiss_store import add_embeddings, create_index

logger = logging.getLogger(__name__)


def run_research_pipeline(job_id: int, topic: str) -> None:
    """
    Execute the full research pipeline for a given job.

    This function is synchronous and intended to be run in a background
    thread (see `research_worker.py`).

    Args:
        job_id: Primary key of the ResearchJob row.
        topic:  Research topic string supplied by the user.
    """
    logger.info("Pipeline started — job_id=%d topic=%r", job_id, topic)
    db = SessionLocal()

    try:
        # ------------------------------------------------------------------
        # Stage 1: retrieve_sources
        # ------------------------------------------------------------------
        _update_job(db, job_id, "retrieving_sources", 5)
        sources = retrieve_sources(topic)
        logger.info("Retrieved %d sources for topic %r", len(sources), topic)

        if not sources:
            logger.warning("No sources found for topic %r — marking job failed", topic)
            _update_job(db, job_id, "failed", 0)
            return

        # ------------------------------------------------------------------
        # Stage 2: fetch_documents — persist Document rows
        # ------------------------------------------------------------------
        _update_job(db, job_id, "fetching_documents", 15)

        for source in sources:
            document = Document(
                job_id=job_id,
                title=source.get("title", ""),
                url=source.get("url") or source.get("pdf_url", ""),
                content=source.get("summary", ""),
                source_type=source.get("source", "unknown"),
            )
            db.add(document)
        db.commit()
        logger.info("Persisted %d document rows for job %d", len(sources), job_id)

        # ------------------------------------------------------------------
        # Stage 3: chunk_documents — split content, persist Chunk rows
        # ------------------------------------------------------------------
        _update_job(db, job_id, "chunking_documents", 30)

        documents: List[Document] = (
            db.query(Document).filter(Document.job_id == job_id).all()
        )
        all_chunk_texts: List[str] = []

        for document in documents:
            if not document.content:
                continue
            chunks = chunk_text(document.content)
            for idx, chunk_text_str in enumerate(chunks):
                chunk_row = Chunk(
                    document_id=document.id,
                    chunk_index=idx,
                    text=chunk_text_str,
                )
                db.add(chunk_row)
                all_chunk_texts.append(chunk_text_str)

        db.commit()
        logger.info("Created %d chunks for job %d", len(all_chunk_texts), job_id)

        # ------------------------------------------------------------------
        # Stage 4: embed_and_index
        # ------------------------------------------------------------------
        _update_job(db, job_id, "embedding_documents", 50)

        if all_chunk_texts:
            embeddings = embed_texts(all_chunk_texts)
            logger.info("Generated %d embeddings for job %d", len(embeddings), job_id)

            dimension = len(embeddings[0])
            index = create_index(dimension)
            add_embeddings(index, embeddings)

            os.makedirs(settings.faiss_index_dir, exist_ok=True)
            index_path = os.path.join(
                settings.faiss_index_dir, f"job_{job_id}.faiss"
            )
            faiss.write_index(index, index_path)
            logger.info("FAISS index saved to %s", index_path)
        else:
            logger.warning(
                "No chunk text available for job %d — skipping embedding stage", job_id
            )

        # ------------------------------------------------------------------
        # Stage 5: generate_outline
        # ------------------------------------------------------------------
        _update_job(db, job_id, "drafting_outline", 65)

        outline_prompt = (
            f"Create a structured research outline for the topic: {topic}.\n\n"
            "Requirements:\n"
            "- Exactly 5 sections\n"
            "- Each section must have a clear title\n"
            "- Include 2–3 bullet points per section\n"
            "- Use an academic tone\n\n"
            "Return only the outline, no preamble."
        )
        outline = generate(outline_prompt)
        logger.info("Outline generated (%d chars)", len(outline))

        # ------------------------------------------------------------------
        # Stage 6: write_report
        # ------------------------------------------------------------------
        _update_job(db, job_id, "writing_report", 80)

        report_prompt = (
            f"Write a 1000-word research report based on the outline below.\n\n"
            f"Topic: {topic}\n\n"
            f"Outline:\n{outline}\n\n"
            "Requirements:\n"
            "- Follow the outline structure exactly\n"
            "- Academic tone, clear explanations\n"
            "- Write in prose (not bullet points)\n"
            "- Do not include a reference list\n"
        )
        report_text = generate(report_prompt)
        logger.info("Report generated (%d chars)", len(report_text))

        # ------------------------------------------------------------------
        # Finalise
        # ------------------------------------------------------------------
        job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
        if job:
            job.result_report = report_text
            job.status = "completed"
            job.progress = 100
            db.commit()
            logger.info("Pipeline completed for job %d", job_id)

    except Exception:
        logger.exception("Pipeline failed for job_id=%d", job_id)
        try:
            _update_job(db, job_id, "failed", 0)
        except Exception:
            logger.exception("Could not mark job %d as failed", job_id)
        raise

    finally:
        db.close()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _update_job(db, job_id: int, status: str, progress: int) -> None:
    """Atomically update job status and progress."""
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if job:
        job.status = status
        job.progress = progress
        db.commit()
        logger.debug("Job %d — status=%r progress=%d%%", job_id, status, progress)
