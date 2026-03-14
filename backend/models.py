"""Modele SQLAlchemy - schema bazei de date (tip Prisma)."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Index

from database import Base


class User(Base):
    """Model utilizator."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False, unique=True, index=True)
    password_hash = Column(String(255), nullable=False, default="")
    auth_provider = Column(String(50), nullable=False, default="local")
    google_id = Column(String(255), nullable=True, index=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    __table_args__ = (
        Index("idx_users_email", "email"),
        Index("idx_users_google_id", "google_id"),
    )
