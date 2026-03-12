from fastapi import FastAPI
from .routers import health

app = FastAPI()

app.include_router(health.router)

@app.get("/health")
def health_check():
    return {"status": "ok"}