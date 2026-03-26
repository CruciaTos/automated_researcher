"""
app/pipeline/base_pipeline.py — Abstract pipeline base.

All three research modes inherit from here.
Shared stages: document persistence, chunking, embedding, FAISS indexing.
Mode-specific stages: retrieve_sources(), generate_report().
"""
import logging
import os
from abc import ABC, abstractmethod
from typing import Any, Dict, List

import faiss

from backend.app.config import settings
from backend.app.embeddings.embedder import embed_texts
from backend.app.llm.llm_provider import LLMProvider
from backend.app.models.base import SessionLocal
from backend.app.models.chunk import Chunk
from backend.app.models.document import Document
from backend.app.models.research_job import ResearchJob
from backend.app.processing.chunker import chunk_text
from backend.app.vector_store.faiss_store import add_embeddings, create_index

logger = logging.getLogger(__name__)


class BaseResearchPipeline(ABC):
    """
    Orchestrates the common pipeline stages.
    Subclasses override retrieve_sources() and generate_report()
    to implement mode-specific behavior.
    """

    def __init__(self, llm: LLMProvider):
        self.llm = llm

    # ── Subclass contract ─────────────────────────────────────────────────

    @property
    @abstractmethod
    def mode_name(self) -> str:
        """'basic' | 'standard' | 'deep'"""
        pass

    @property
    @abstractmethod
    def max_sources(self) -> int:
        pass

    @abstractmethod
    def retrieve_sources(self, topic: str) -> List[Dict[str, Any]]:
        """Retrieve and filter sources. Mode-specific logic lives here."""
        pass

    @abstractmethod
    def generate_report(
        self,
        topic: str,
        sources: List[Dict[str, Any]],
        context: str,
    ) -> str:
        """Generate the final report string using self.llm."""
        pass

    # ── Common orchestration ──────────────────────────────────────────────

    def run(self, job_id: int, topic: str) -> None:
        logger.info(
            "Pipeline[%s] started — job_id=%d topic=%r",
            self.mode_name, job_id, topic,
        )
        db = SessionLocal()

        try:
            # Stage 1: Retrieve
            _set_status(db, job_id, "retrieving_sources", 5)
            sources = self.retrieve_sources(topic)
            logger.info("[%s] %d sources retrieved", self.mode_name, len(sources))

            if not sources:
                logger.warning("[%s] No sources — failing job %d", self.mode_name, job_id)
                _set_status(db, job_id, "failed", 0)
                return

            # Stage 2: Persist documents
            _set_status(db, job_id, "fetching_documents", 15)
            for src in sources:
                db.add(Document(
                    job_id=job_id,
                    title=src.get("title", ""),
                    url=src.get("url") or src.get("pdf_url", ""),
                    content=src.get("summary", ""),
                    source_type=src.get("source", "unknown"),
                ))
            db.commit()

            # Stage 3: Chunk
            _set_status(db, job_id, "chunking_documents", 30)
            documents = db.query(Document).filter(Document.job_id == job_id).all()
            all_chunks: List[str] = []

            for doc in documents:
                if not doc.content:
                    continue
                for idx, text in enumerate(chunk_text(doc.content)):
                    db.add(Chunk(document_id=doc.id, chunk_index=idx, text=text))
                    all_chunks.append(text)
            db.commit()

            # Stage 4: Embed & index
            _set_status(db, job_id, "embedding_documents", 50)
            if all_chunks:
                embeddings = embed_texts(all_chunks)
                dimension = len(embeddings[0])
                index = create_index(dimension)
                add_embeddings(index, embeddings)
                os.makedirs(settings.faiss_index_dir, exist_ok=True)
                faiss.write_index(
                    index,
                    os.path.join(settings.faiss_index_dir, f"job_{job_id}.faiss"),
                )
                logger.info("[%s] FAISS index saved (%d vectors)", self.mode_name, len(embeddings))

            # Stage 5: Draft outline (status marker — logic in generate_report)
            _set_status(db, job_id, "drafting_outline", 65)
            context = _build_context(sources)

            # Stage 6: Write report
            _set_status(db, job_id, "writing_report", 80)
            report_text = self.generate_report(topic, sources, context)

            # Finalise
            job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
            if job:
                job.result_report = report_text
                job.status = "completed"
                job.progress = 100
                db.commit()
                logger.info("Pipeline[%s] completed — job_id=%d", self.mode_name, job_id)

        except Exception:
            logger.exception("Pipeline[%s] failed — job_id=%d", self.mode_name, job_id)
            try:
                _set_status(db, job_id, "failed", 0)
            except Exception:
                pass
            raise
        finally:
            db.close()


# ── Module-level helpers (shared across all pipeline files) ───────────────

def _set_status(db, job_id: int, status: str, progress: int) -> None:
    job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
    if job:
        job.status = status
        job.progress = progress
        db.commit()
        logger.debug("job %d → %s (%d%%)", job_id, status, progress)


def _build_context(sources: List[Dict[str, Any]], max_chars_per_source: int = 1000) -> str:
    """Concatenate source summaries into an LLM-ready context block."""
    parts = []
    for i, src in enumerate(sources, 1):
        title = src.get("title", "Unknown")
        summary = (src.get("summary") or "")[:max_chars_per_source]
        url = src.get("url") or src.get("pdf_url", "")
        parts.append(f"[{i}] {title}\nURL: {url}\n{summary}")
    return "\n\n---\n\n".join(parts)