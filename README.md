# ACIO

ACIO este o aplicație de fitness gamificată, în care utilizatorul face exerciții fizice ghidate, primește XP, level, streak și achievements, iar repetările sunt detectate automat cu pose detection direct pe telefon.

Aplicația este construită în jurul a 3 exerciții principale:

- **Flotări**
- **Genuflexiuni**
- **Jumping Jacks**

Procesarea exercițiilor se face **on-device**, folosind camera telefonului și Google ML Kit Pose Detection.

## Status proiect

| Componentă | Tehnologie | Status |
|-----------|------------|--------|
| **Mobile app** | Flutter | ✅ Versiunea principală |
| **Pose detection** | Google ML Kit Pose Detection | ✅ Integrat |
| **Backend API** | FastAPI + SQLAlchemy + Alembic | ✅ Integrat |
| **Autentificare locală** | SQLite + SharedPreferences | ✅ Disponibilă |
| **Autentificare server** | JWT + Google Sign-In | ✅ Disponibilă |

## Funcționalități principale

- autentificare cu:
  - email + parolă
  - Google Sign-In
- **daily quests** generate dinamic
- **The Path** cu questuri progresive
- tutorial video înainte de exercițiile din daily quests
- detectare automată a repetărilor prin cameră
- sistem de:
  - **XP**
  - **Level**
  - **Gems**
  - **Streak**
  - **Best streak**
- sistem de **achievements**
- **leaderboard global**
- **notificări locale** pentru streak reminder
- setare pentru activare/dezactivare overlay-ului vizual al exercițiilor
- suport pentru stocare:
  - pe server
  - local, în SQLite

## Tech Stack (Mobile)

- **Flutter**
- **camera**
- **google_mlkit_pose_detection**
- **shared_preferences**
- **sqflite**
- **flutter_local_notifications**
- **timezone**
- **video_player**
- **google_sign_in**
- **http**

## Structura proiectului

```text
ACIO/
├── mobile/
│   ├── lib/
│   │   ├── config/
│   │   │   ├── api_config.dart
│   │   │   └── storage_config.dart
│   │   ├── data/
│   │   │   ├── achievements_data.dart
│   │   │   └── quest_data.dart
│   │   ├── models/
│   │   │   ├── achievement.dart
│   │   │   ├── app_user.dart
│   │   │   ├── player_progress.dart
│   │   │   └── quest.dart
│   │   ├── screens/
│   │   │   ├── achievements_screen.dart
│   │   │   ├── exercise_tutorial_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── path_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   ├── stretch_tutorial_screen.dart
│   │   │   ├── stretching_screen.dart
│   │   │   ├── workout/
│   │   │   ├── workout_screen.dart
│   │   │   └── worldwide_rankings_screen.dart
│   │   ├── services/
│   │   │   ├── api_client.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── database_service.dart
│   │   │   ├── exercise_counter.dart
│   │   │   ├── local_storage_service.dart
│   │   │   ├── pose_service.dart
│   │   │   └── streak_reminder_notification_service.dart
│   │   ├── widgets/
│   │   │   ├── achievement_icon.dart
│   │   │   └── home/
│   │   └── main.dart
│   ├── assets/
│   │   ├── images/
│   │   └── videos/tutorials/
│   └── pubspec.yaml
├── backend/
│   ├── alembic/
│   ├── routers/
│   ├── auth_utils.py
│   ├── config.py
│   ├── database.py
│   ├── gamification_logic.py
│   ├── main.py
│   ├── models.py
│   ├── requirements.txt
│   └── schemas.py
└── README.md
