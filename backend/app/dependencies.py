# app/models/base.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session

# Import the settings singleton that loads env vars
from config import settings

# -------------------------------------------------
# SQLAlchemy core configuration
# -------------------------------------------------
# `settings.database_url` is a string; ensure it is passed to SQLAlchemy
engine = create_engine(str(settings.database_url), echo=False, future=True)

# `SessionLocal` will be used to create new Session objects
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, class_=Session)

# Base class for all model definitions
Base = declarative_base()


# -------------------------------------------------
# FastAPI dependency for DB sessions
# -------------------------------------------------
def get_db():
    """
    FastAPI dependency that provides a database session.

    Usage in a path operation:

        @app.get("/items/")
        def read_items(db: Session = Depends(get_db)):
            ...

    The generator yields a `Session` and ensures it is closed after the request.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
