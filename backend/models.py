"""Modele SQLAlchemy - schema bazei de date (tip Prisma)."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Index, ForeignKey
from sqlalchemy.orm import relationship

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

    progress = relationship("PlayerProgress", back_populates="user", uselist=False)
    quest_completions = relationship("QuestProgress", back_populates="user")


class PlayerProgress(Base):
    """Progres jucător: level, XP, gems, streak, totaluri exerciții."""

    __tablename__ = "player_progress"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    level = Column(Integer, nullable=False, default=1)
    xp = Column(Integer, nullable=False, default=0)
    total_xp = Column(Integer, nullable=False, default=0)
    xp_for_next = Column(Integer, nullable=False, default=100)
    gems = Column(Integer, nullable=False, default=0)
    streak_days = Column(Integer, nullable=False, default=0)
    best_streak_days = Column(Integer, nullable=False, default=0)
    total_pushups = Column(Integer, nullable=False, default=0)
    total_squats = Column(Integer, nullable=False, default=0)
    total_jumping_jacks = Column(Integer, nullable=False, default=0)
    total_workouts_completed = Column(Integer, nullable=False, default=0)
    total_daily_challenges_completed = Column(Integer, nullable=False, default=0)
    last_streak_date = Column(String(32), nullable=True)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    user = relationship("User", back_populates="progress")


class QuestProgress(Base):
    """Quest completat de un user (user_id, quest_id)."""

    __tablename__ = "quest_progress"

    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    quest_id = Column(Integer, primary_key=True)
    completed_at = Column(DateTime, nullable=False, default=datetime.utcnow)

    user = relationship("User", back_populates="quest_completions")
