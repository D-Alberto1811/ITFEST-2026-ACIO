"""Router gamification: progress, complete-quest, leaderboard."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database import get_db
from models import User, PlayerProgress, QuestProgress
from routers.auth import _get_current_user
from schemas import (
    ProgressResponse,
    CompleteQuestRequest,
    CompleteQuestResponse,
    LeaderboardEntryResponse,
    LeaderboardResponse,
)
from gamification_logic import (
    compute_streak,
    apply_level_ups,
    unlocked_achievements,
)

router = APIRouter(prefix="/gamification", tags=["gamification"])
security = HTTPBearer(auto_error=False)


@router.get("")
def gamification_root():
    """Verificare că prefix-ul /gamification este montat (fără auth)."""
    return {"status": "ok", "routes": ["/progress", "/complete-quest", "/leaderboard"]}


# Recompense implicite dacă clientul nu le trimite (quest-urile sunt definite în app)
DEFAULT_QUEST_XP = 15
DEFAULT_QUEST_GEMS = 1


def _get_or_create_progress(db: Session, user_id: int) -> PlayerProgress:
    progress = db.query(PlayerProgress).filter(PlayerProgress.user_id == user_id).first()
    if progress is not None:
        return progress
    progress = PlayerProgress(
        user_id=user_id,
        level=1,
        xp=0,
        total_xp=0,
        xp_for_next=100,
        gems=0,
        streak_days=0,
        best_streak_days=0,
        total_pushups=0,
        total_squats=0,
        total_jumping_jacks=0,
        total_workouts_completed=0,
        total_daily_challenges_completed=0,
        last_streak_date=None,
        updated_at=datetime.utcnow(),
    )
    db.add(progress)
    db.commit()
    db.refresh(progress)
    return progress


@router.get("/progress", response_model=ProgressResponse)
def get_progress(
    creds: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
):
    """Progres utilizator: level, XP, gems, streak, quest-uri completate, achievements."""
    user = _get_current_user(creds, db)
    progress = _get_or_create_progress(db, user.id)
    completed_ids = [
        r[0] for r in db.query(QuestProgress.quest_id).filter(QuestProgress.user_id == user.id).all()
    ]
    achievements = unlocked_achievements(
        progress.level,
        progress.streak_days,
        progress.total_pushups,
        progress.total_squats,
        progress.total_jumping_jacks,
    )
    return ProgressResponse(
        user_id=user.id,
        level=progress.level,
        xp=progress.xp,
        total_xp=progress.total_xp,
        xp_for_next=progress.xp_for_next,
        gems=progress.gems,
        streak_days=progress.streak_days,
        best_streak_days=progress.best_streak_days,
        total_pushups=progress.total_pushups,
        total_squats=progress.total_squats,
        total_jumping_jacks=progress.total_jumping_jacks,
        total_workouts_completed=progress.total_workouts_completed,
        total_daily_challenges_completed=progress.total_daily_challenges_completed,
        last_streak_date=progress.last_streak_date,
        updated_at=progress.updated_at.isoformat() if progress.updated_at else "",
        completed_quest_ids=completed_ids,
        unlocked_achievements=achievements,
    )


@router.post("/complete-quest", response_model=CompleteQuestResponse)
def complete_quest(
    body: CompleteQuestRequest,
    creds: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
):
    """Înregistrează completarea unui quest: XP, gems, streak, totaluri exerciții."""
    user = _get_current_user(creds, db)
    progress = _get_or_create_progress(db, user.id)

    # Evită double-complete
    existing = db.query(QuestProgress).filter(
        QuestProgress.user_id == user.id,
        QuestProgress.quest_id == body.quest_id,
    ).first()
    if existing:
        return CompleteQuestResponse(
            level=progress.level,
            xp=progress.xp,
            total_xp=progress.total_xp,
            xp_for_next=progress.xp_for_next,
            gems=progress.gems,
            streak_days=progress.streak_days,
            updated_at=progress.updated_at.isoformat() if progress.updated_at else None,
            xp_earned=0,
            gems_earned=0,
        )

    xp_earned = body.reward_xp if body.reward_xp is not None else DEFAULT_QUEST_XP
    gems_earned = body.reward_gems if body.reward_gems is not None else DEFAULT_QUEST_GEMS

    # Streak (zi curentă)
    new_streak, new_last_date = compute_streak(
        progress.last_streak_date,
        progress.streak_days,
    )
    progress.streak_days = new_streak
    progress.last_streak_date = new_last_date
    if new_streak > progress.best_streak_days:
        progress.best_streak_days = new_streak

    # Total XP și level-up
    progress.total_xp += xp_earned
    new_level, new_xp, new_xp_for_next = apply_level_ups(
        progress.level,
        progress.xp,
        progress.xp_for_next,
        xp_earned,
    )
    progress.level = new_level
    progress.xp = new_xp
    progress.xp_for_next = new_xp_for_next
    progress.gems += gems_earned

    # Totaluri exerciții
    if body.exercise_type == "pushup":
        progress.total_pushups += body.reps_completed
    elif body.exercise_type == "squat":
        progress.total_squats += body.reps_completed
    elif body.exercise_type == "jumping_jack":
        progress.total_jumping_jacks += body.reps_completed
    progress.total_workouts_completed += 1

    progress.updated_at = datetime.utcnow()

    db.add(QuestProgress(user_id=user.id, quest_id=body.quest_id, completed_at=datetime.utcnow()))
    db.commit()
    db.refresh(progress)

    return CompleteQuestResponse(
        level=progress.level,
        xp=progress.xp,
        total_xp=progress.total_xp,
        xp_for_next=progress.xp_for_next,
        gems=progress.gems,
        streak_days=progress.streak_days,
        updated_at=progress.updated_at.isoformat() if progress.updated_at else None,
        xp_earned=xp_earned,
        gems_earned=gems_earned,
    )


@router.get("/leaderboard", response_model=LeaderboardResponse)
def get_leaderboard(
    category: str,  # pushups | squats | jumping_jacks
    creds: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
):
    """Leaderboard pe categorie: pushups, squats, jumping_jacks."""
    user = _get_current_user(creds, db)
    _get_or_create_progress(db, user.id)

    if category == "pushups":
        score_col = PlayerProgress.total_pushups
    elif category == "squats":
        score_col = PlayerProgress.total_squats
    elif category == "jumping_jacks":
        score_col = PlayerProgress.total_jumping_jacks
    else:
        raise HTTPException(status_code=400, detail="Invalid category. Use pushups, squats, or jumping_jacks.")

    # Toți userii cu progress, ordonați după score desc
    rows = (
        db.query(User.id, User.name, score_col)
        .join(PlayerProgress, User.id == PlayerProgress.user_id)
        .order_by(score_col.desc())
        .limit(100)
        .all()
    )
    entries = []
    for rank, (uid, name, score) in enumerate(rows, start=1):
        entries.append(
            LeaderboardEntryResponse(
                rank=rank,
                name=(name or "").strip() or "Unknown Athlete",
                score=score or 0,
                user_id=uid,
                is_current_user=(uid == user.id),
            )
        )
    return LeaderboardResponse(entries=entries)
