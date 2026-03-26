# Research API — Backend

Automated research pipeline backed by local LLMs (Ollama), Wikipedia, arXiv,
sentence-transformers embeddings, and a FAISS vector store.

---

## Project Structure

```
backend/
├── app/
│   ├── main.py                  # FastAPI entrypoint
│   ├── config.py                # Centralised settings (env vars)
│   ├── dependencies.py          # Re-exports get_db for backward compat
│   ├── auth/
│   │   └── firebase_auth.py     # Firebase ID token verification
│   ├── embeddings/
│   │   └── embedder.py          # sentence-transformers wrapper
│   ├── llm/
│   │   └── ollama_client.py     # Ollama HTTP client
│   ├── models/
│   │   ├── base.py              # SQLAlchemy Base + get_db dependency
│   │   ├── chunk.py             # Chunk ORM model
│   │   ├── document.py          # Document ORM model
│   │   └── research_job.py      # ResearchJob ORM model
│   ├── pipeline/
│   │   └── research_pipeline.py # Full 6-stage pipeline orchestrator
│   ├── processing/
│   │   └── chunker.py           # Overlapping text chunker
│   ├── retrieval/
│   │   ├── arxiv.py             # arXiv Atom API client
│   │   ├── source_router.py     # Aggregates all retrieval backends
│   │   └── wikipedia.py         # Wikipedia API client
│   ├── routers/
│   │   ├── health.py            # GET /health, GET /health/db
│   │   └── jobs.py              # CRUD + /report, /sources, /chat
│   ├── schemas/
│   │   └── research_job.py      # Pydantic request/response schemas
│   ├── vector_store/
│   │   └── faiss_store.py       # FAISS index helpers
│   └── workers/
│       ├── cleanup_worker.py    # Deletes expired jobs
│       └── research_worker.py   # Background task dispatcher
├── .env.example                 # Environment variable template
├── requirements.txt
└── README.md
```

---

## Quick Start

### 1. Prerequisites

- Python 3.11+
- [Ollama](https://ollama.com) running locally with your chosen model pulled:
  ```bash
  ollama pull qwen2.5:7b
  ```

### 2. Install dependencies

```bash
cd backend
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure environment

```bash
cp .env.example .env
# Edit .env — at minimum verify OLLAMA_HOST and OLLAMA_MODEL
```

### 4. Run

```bash
uvicorn backend.app.main:app --reload
```

API docs available at: http://localhost:8000/docs

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Liveness check |
| GET | /health/db | Database connectivity check |
| POST | /jobs | Create a new research job |
| GET | /jobs | List all jobs (paginated) |
| GET | /jobs/{id} | Get job status + metadata |
| GET | /jobs/{id}/report | Get generated report |
| GET | /jobs/{id}/sources | List retrieved sources |
| POST | /jobs/{id}/chat | Ask a question about a job |

---

## Pipeline Stages

```
queued
  → retrieving_sources   (5%)
  → fetching_documents   (15%)
  → chunking_documents   (30%)
  → embedding_documents  (50%)
  → drafting_outline     (65%)
  → writing_report       (80%)
  → completed            (100%)
  | failed               (on error)
```

---

## Environment Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DATABASE_URL` | `sqlite:///./sql_backend.app.db` | No | DB connection string |
| `OLLAMA_HOST` | `http://localhost:11434` | No | Ollama server URL |
| `OLLAMA_MODEL` | `qwen2.5:7b` | No | Model to use for generation |
| `OLLAMA_TIMEOUT` | `120` | No | Request timeout in seconds |
| `EMBEDDING_MODEL` | `BAAI/bge-small-en-v1.5` | No | HuggingFace model ID |
| `FAISS_INDEX_DIR` | `data/indexes` | No | Directory for FAISS index files |
| `MAX_SOURCES` | `10` | No | Max sources retrieved per job |
| `JOB_EXPIRY_DAYS` | `3` | No | Days before job cleanup |
| `GOOGLE_APPLICATION_CREDENTIALS` | — | Only for auth | Path to Firebase service account JSON |

---

## Known Limitations / Future Work

- **SQLite** is the default — not suitable for concurrent production use.
  Switch to PostgreSQL by setting `DATABASE_URL`.
- **Chat endpoint** currently retrieves chunks by insertion order, not
  semantic similarity. To enable proper RAG, load the FAISS index for the
  job and query it with the embedded question.
- **Firebase auth** is wired up in `auth/firebase_auth.py` but not applied
  as a router dependency by default. Add `Depends(get_current_user)` to
  secure endpoints as needed.
- **FAISS indexes** are stored on local disk — incompatible with multi-replica
  deployments. Use a shared volume or migrate to a hosted vector DB.
