from fastapi import FastAPI

from .config import engine
from .models.base import Base
from .models import research_job
from .routers import health, jobs

Base.metadata.create_all(bind=engine)

app = FastAPI()

app.include_router(health.router)
app.include_router(jobs.router)