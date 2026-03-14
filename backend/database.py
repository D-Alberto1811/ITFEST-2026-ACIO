"""Conexiune și sesiune SQLAlchemy."""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_recycle=3600,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """Dependency pentru sesiune DB."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
