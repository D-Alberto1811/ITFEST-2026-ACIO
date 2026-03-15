"""Logică gamification: XP, level, streak, achievements – aliniată cu app-ul Flutter."""
from datetime import date, datetime
from typing import List

# Achievements: (id, type, target). type = streak | pushup | squat | jumping_jack | level
ACHIEVEMENTS = [
    ("streak_3", "streak", 3), ("streak_7", "streak", 7), ("streak_30", "streak", 30),
    ("streak_100", "streak", 100), ("streak_365", "streak", 365), ("streak_730", "streak", 730),
    ("streak_1095", "streak", 1095),
    ("pushups_10", "pushup", 10), ("pushups_50", "pushup", 50), ("pushups_200", "pushup", 200),
    ("pushups_1000", "pushup", 1000), ("pushups_5000", "pushup", 5000), ("pushups_10000", "pushup", 10000),
    ("pushups_25000", "pushup", 25000), ("pushups_50000", "pushup", 50000), ("pushups_100000", "pushup", 100000),
    ("squats_10", "squat", 10), ("squats_50", "squat", 50), ("squats_200", "squat", 200),
    ("squats_1000", "squat", 1000), ("squats_5000", "squat", 5000), ("squats_10000", "squat", 10000),
    ("squats_25000", "squat", 25000), ("squats_50000", "squat", 50000), ("squats_100000", "squat", 100000),
    ("jacks_10", "jumping_jack", 10), ("jacks_50", "jumping_jack", 50), ("jacks_200", "jumping_jack", 200),
    ("jacks_1000", "jumping_jack", 1000), ("jacks_5000", "jumping_jack", 5000), ("jacks_10000", "jumping_jack", 10000),
    ("jacks_25000", "jumping_jack", 25000), ("jacks_50000", "jumping_jack", 50000), ("jacks_100000", "jumping_jack", 100000),
    ("level_5", "level", 5), ("level_25", "level", 25), ("level_50", "level", 50), ("level_100", "level", 100),
]


def _date_key(d: datetime) -> str:
    return d.date().isoformat()


def compute_streak(last_streak_date: str | None, streak_days: int) -> tuple[int, str]:
    """Actualizează streak: last_streak_date (YYYY-MM-DD), streak_days curent. Returnează (new_streak_days, new_last_streak_date)."""
    today_key = date.today().isoformat()
    if last_streak_date is None:
        return 1, today_key
    try:
        last_day = date.fromisoformat(last_streak_date)
    except ValueError:
        return 1, today_key
    today = date.today()
    diff = (today - last_day).days
    if diff <= 0:
        return streak_days, last_streak_date
    if diff == 1:
        return streak_days + 1, today_key
    return 1, today_key


def apply_level_ups(level: int, xp: int, xp_for_next: int, total_xp_delta: int) -> tuple[int, int, int]:
    """După ce adăugăm total_xp_delta la total_xp, avem xp += reward_xp. Aplică level-up-uri: while xp >= xp_for_next -> level++, xp -= xp_for_next, xp_for_next = int(xp_for_next * 1.5). Returnează (new_level, new_xp, new_xp_for_next)."""
    xp_remaining = xp + total_xp_delta
    while xp_remaining >= xp_for_next:
        xp_remaining -= xp_for_next
        level += 1
        xp_for_next = int(xp_for_next * 1.5)
    return level, xp_remaining, xp_for_next


def unlocked_achievements(
    level: int,
    streak_days: int,
    total_pushups: int,
    total_squats: int,
    total_jumping_jacks: int,
) -> List[str]:
    """Lista de id-uri achievements deblocate."""
    out = []
    for aid, atype, target in ACHIEVEMENTS:
        val = {
            "streak": streak_days,
            "pushup": total_pushups,
            "squat": total_squats,
            "jumping_jack": total_jumping_jacks,
            "level": level,
        }.get(atype, 0)
        if val >= target:
            out.append(aid)
    return out
