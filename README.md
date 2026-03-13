# FitLingo

Aplicație de fitness gamificată (tip "Duolingo pentru sport") cu detectare pose în timp real: Flotări, Genuflexiuni, Jumping Jacks. **100% on-device** – procesarea se face local pe telefon (GDPR compliant).

## Versiuni

| Platformă | Tehnologie | Status |
|-----------|------------|--------|
| **Android (mobile)** | Flutter + ML Kit Pose | ✅ Recomandat |
| Web | React + MediaPipe | Există (frontend/) |
| Backend | FastAPI + MySQL | Există (backend/) |

## Tech Stack (Mobile)

- **Flutter** - UI cross-platform
- **Google ML Kit Pose Detection** - On-device, 0 date externe
- **Camera** - CameraX pentru frame-uri

## Structură

```
FitLingo/
├── mobile/             # Flutter Android (RECOMANDAT)
│   ├── lib/
│   │   ├── screens/    # Home, Workout
│   │   ├── services/   # PoseService, ExerciseCounter
│   │   └── models/
│   └── SETUP.md        # Setup complet pentru telefon
├── frontend/           # React + Vite (web)
├── backend/
│   ├── main.py        # FastAPI
│   ├── config.py     # Settings (DATABASE_URL etc.)
│   ├── database.py   # SQLAlchemy engine
│   ├── models.py     # User, Player, PathNode, WorkoutSession
│   ├── services/     # player_service
│   └── alembic/      # Migrații (Prisma-like)
└── README.md
```

## Baza de Date (MySQL)

**Conexiune:** `mysql+pymysql://root@localhost:3306/itfest`

### Setup inițial

```bash
cd backend
source venv/bin/activate
python -m scripts.init_db
```

Creează baza `itfest`, tabelele și userul default `guest`.

Când MySQL nu e disponibil, aplicația folosește fallback in-memory (SQLite).

## Rulare

### Mobile (Android) – RECOMANDAT

```bash
cd mobile
# Vezi SETUP.md pentru instalare Flutter + Android Studio
flutter create . --org com.fitlingo

flutter pub get
flutter run
```

Conectează telefonul prin USB cu USB debugging activat.

### Backend (opțional, pentru sync)

```bash
cd backend
source venv/bin/activate
uvicorn main:app --reload
```

### Frontend

```bash
cd frontend && npm install && npm run dev
```

## Mecanici

- **XP & Level:** Acordate la finalizarea quest-urilor
- **Gems:** Monedă in-app (Vieți, cosmetice Barnaby)
- **Streaks:** Zile consecutive cu activitate
- **The Path:** Traseu vertical cu noduri deblocate progresiv
- **Barnaby Ursul:** Mascotă (placeholder)
- **Anti-Cheat:** DeviceOrientationEvent (giroscop), body tilt (placeholder)
