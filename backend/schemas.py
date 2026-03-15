"""Pydantic schemas pentru request/response."""
from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    """Răspuns utilizator."""

    id: int
    name: str
    email: str
    auth_provider: str
    created_at: str

    class Config:
        from_attributes = True


class RegisterRequest(BaseModel):
    """Request înregistrare."""

    name: str
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    """Request login."""

    email: EmailStr
    password: str


class GoogleAuthRequest(BaseModel):
    """Request Google OAuth - id_token de la Flutter."""

    id_token: str


class TokenResponse(BaseModel):
    """Răspuns cu JWT și user."""

    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ----- Gamification -----


class ProgressResponse(BaseModel):
    """Răspuns GET /gamification/progress – aliniat cu app."""

    user_id: int
    level: int = 1
    xp: int = 0
    total_xp: int = 0
    xp_for_next: int = 100
    gems: int = 0
    streak_days: int = 0
    best_streak_days: int = 0
    total_pushups: int = 0
    total_squats: int = 0
    total_jumping_jacks: int = 0
    total_workouts_completed: int = 0
    total_daily_challenges_completed: int = 0
    last_streak_date: str | None = None
    updated_at: str
    completed_quest_ids: list[int] = []
    unlocked_achievements: list[str] = []


class CompleteQuestRequest(BaseModel):
    """Body POST /gamification/complete-quest."""

    quest_id: int
    exercise_type: str  # pushup | squat | jumping_jack
    reps_completed: int
    difficulty: str = "beginner"
    reward_xp: int | None = None  # optional, from app quest definition
    reward_gems: int | None = None


class CompleteQuestResponse(BaseModel):
    """Răspuns POST /gamification/complete-quest."""

    level: int
    xp: int
    total_xp: int
    xp_for_next: int
    gems: int
    streak_days: int
    updated_at: str | None = None
    xp_earned: int = 0
    gems_earned: int = 0


class LeaderboardEntryResponse(BaseModel):
    """Un entry în leaderboard."""

    rank: int
    name: str
    score: int
    user_id: int
    is_current_user: bool = False


class LeaderboardResponse(BaseModel):
    """Răspuns GET /gamification/leaderboard."""

    entries: list[LeaderboardEntryResponse]
