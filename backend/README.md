# FitLingo Backend

API FastAPI: auth (register, login, Google) + gamification (progress, complete-quest, leaderboard).  
Aliniat cu aplicația Flutter (modelele și fluxurile sunt aceleași ca pe SQLite).

## Pornire

```bash
# Instalare dependențe
pip install -r requirements.txt

# Variabile de mediu (opțional, există default-uri în config.py)
export DATABASE_URL="mysql+pymysql://user:pass@host:3306/dbname"
export JWT_SECRET="your-secret"
export GOOGLE_CLIENT_ID="web-client-id,ios-client-id"

# Migrări (crează tabelele users, player_progress, quest_progress)
alembic upgrade head

# Server
uvicorn main:app --reload --host 0.0.0.0 --port 8999
```

## Endpoints

- **POST /auth/register** – name, email, password → token + user (și progres inițial)
- **POST /auth/login** – email, password → token + user
- **POST /auth/google** – id_token → token + user (și progres inițial la user nou)
- **GET /auth/me** – Bearer token → user
- **GET /gamification/progress** – Bearer → level, xp, gems, streak_days, completed_quest_ids, unlocked_achievements
- **POST /gamification/complete-quest** – Bearer + quest_id, exercise_type, reps_completed, difficulty [, reward_xp, reward_gems ] → progres actualizat
- **GET /gamification/leaderboard?category=pushups|squats|jumping_jacks** – Bearer → entries (rank, name, score, user_id, is_current_user)

## Comutare app pe server

În `mobile/lib/config/storage_config.dart` setează:

```dart
const StorageMode appStorageMode = StorageMode.server;
```

Și în `api_config.dart` pune URL-ul backend-ului tău (ex: `http://194.102.62.209:8999`).
