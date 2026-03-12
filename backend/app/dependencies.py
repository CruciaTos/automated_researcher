from fastapi import Depends
from sqlalchemy.orm import Session
from .config import get_db

db: Session = Depends(get_db)