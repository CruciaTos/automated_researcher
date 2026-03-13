import os

import faiss

from app.embeddings.embedder import embed_texts
from app.llm.ollama_client import generate
from app.models.base import SessionLocal
from app.models.document import Document
from app.models.research_job import ResearchJob
from app.processing.chunker import chunk_text
from app.retrieval.source_router import retrieve_sources
from app.vector_store.faiss_store import add_embeddings, create_index

def run_research_pipeline(job_id: int, topic: str) -> None:
    """Placeholder research pipeline orchestrator."""
    sources = retrieve_sources(topic)
    print(f"Retrieved {len(sources)} sources for topic: {topic}")
    documents = []
    all_chunks = []
    db = SessionLocal()
    try:
        # Stage: fetch_documents
        for source in sources:
            document = Document(
                job_id=job_id,
                title=source["title"],
                url=source["url"],
                content=source.get("summary"),
                source_type=source["source"],
            )
            db.add(document)
        db.commit()

        # Stage: load_documents
        documents = db.query(Document).filter(Document.job_id == job_id).all()
        print(f"Loaded {len(documents)} documents for job {job_id}")

        # Stage: chunk_documents
        all_chunks = []
        for document in documents:
            if not document.content:
                continue
            chunks = chunk_text(document.content)
            all_chunks.extend(chunks)
        print(f"Total chunks created: {len(all_chunks)}")
        embeddings = embed_texts(all_chunks)
        print(f"Generated {len(embeddings)} embeddings")
        dimension = len(embeddings[0])
        index = create_index(dimension)
        add_embeddings(index, embeddings)
        print(f"FAISS index created with {len(embeddings)} vectors")
        os.makedirs("data/indexes", exist_ok=True)
        faiss.write_index(index, f"data/indexes/job_{job_id}.faiss")
        print(f"Saved FAISS index to data/indexes/job_{job_id}.faiss")

        # Stage: generate_outline
        prompt = f"""
Create a structured research outline for the topic: {topic}.

Requirements:
- 5 sections
- Each section should have a title
- Include 2–3 bullet points per section
- Academic tone

Return only the outline.
"""
        try:
            outline = generate(prompt, model="qwen2.5:7b")
        except TypeError:
            outline = generate(prompt)
        print(outline)

        # Stage: write_report
        report_prompt = f"""
Write a 1000 word research report based on this outline:

{outline}

Topic: {topic}

Requirements:
- structured sections
- academic tone
- clear explanations
"""
        try:
            report_text = generate(report_prompt, model="qwen2.5:7b")
        except TypeError:
            report_text = generate(report_prompt)
        print(report_text[:200])
        job = db.query(ResearchJob).filter(ResearchJob.id == job_id).first()
        if job:
            job.result_report = report_text
            job.status = "completed"
            job.progress = 100
            db.commit()
        print(f"Report saved for job {job_id}")
    finally:
        db.close()