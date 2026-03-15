"""Gamification: player_progress, quest_progress.

Revision ID: 002
Revises: 001
Create Date: 2026-03-15

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "player_progress",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("level", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("xp", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_xp", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("xp_for_next", sa.Integer(), nullable=False, server_default="100"),
        sa.Column("gems", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("streak_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("best_streak_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_pushups", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_squats", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_jumping_jacks", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_workouts_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_daily_challenges_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_streak_date", sa.String(32), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("user_id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
    )
    op.create_table(
        "quest_progress",
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("quest_id", sa.Integer(), nullable=False),
        sa.Column("completed_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint("user_id", "quest_id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
    )


def downgrade() -> None:
    op.drop_table("quest_progress")
    op.drop_table("player_progress")
