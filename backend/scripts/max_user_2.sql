-- Maxează contul cu user_id = 2 pentru testare (level, XP, gems, streak, totaluri, quest-uri path completate).
-- Rulează: mysql -u root -p itfest < scripts/max_user_2.sql
-- Sau din MySQL client: source scripts/max_user_2.sql (după USE itfest;)

-- 1) Asigură-te că există player_progress pentru user_id = 2, apoi pune totul la max
INSERT INTO player_progress (
  user_id, level, xp, total_xp, xp_for_next, gems,
  streak_days, best_streak_days,
  total_pushups, total_squats, total_jumping_jacks,
  total_workouts_completed, total_daily_challenges_completed,
  last_streak_date, updated_at
) VALUES (
  2,
  50,
  0,
  999999,
  5000,
  9999,
  365,
  365,
  100000,
  100000,
  100000,
  500,
  99,
  DATE_FORMAT(CURDATE(), '%Y-%m-%d'),
  NOW()
)
ON DUPLICATE KEY UPDATE
  level = 50,
  xp = 0,
  total_xp = 999999,
  xp_for_next = 5000,
  gems = 9999,
  streak_days = 365,
  best_streak_days = 365,
  total_pushups = 100000,
  total_squats = 100000,
  total_jumping_jacks = 100000,
  total_workouts_completed = 500,
  total_daily_challenges_completed = 99,
  last_streak_date = DATE_FORMAT(CURDATE(), '%Y-%m-%d'),
  updated_at = NOW();

-- 2) Marchează toate quest-urile Path (id 100–149) ca completate pentru user_id = 2
INSERT IGNORE INTO quest_progress (user_id, quest_id, completed_at) VALUES
(2, 100, NOW()), (2, 101, NOW()), (2, 102, NOW()), (2, 103, NOW()), (2, 104, NOW()), (2, 105, NOW()), (2, 106, NOW()), (2, 107, NOW()), (2, 108, NOW()), (2, 109, NOW()),
(2, 110, NOW()), (2, 111, NOW()), (2, 112, NOW()), (2, 113, NOW()), (2, 114, NOW()), (2, 115, NOW()), (2, 116, NOW()), (2, 117, NOW()), (2, 118, NOW()), (2, 119, NOW()),
(2, 120, NOW()), (2, 121, NOW()), (2, 122, NOW()), (2, 123, NOW()), (2, 124, NOW()), (2, 125, NOW()), (2, 126, NOW()), (2, 127, NOW()), (2, 128, NOW()), (2, 129, NOW()),
(2, 130, NOW()), (2, 131, NOW()), (2, 132, NOW()), (2, 133, NOW()), (2, 134, NOW()), (2, 135, NOW()), (2, 136, NOW()), (2, 137, NOW()), (2, 138, NOW()), (2, 139, NOW()),
(2, 140, NOW()), (2, 141, NOW()), (2, 142, NOW()), (2, 143, NOW()), (2, 144, NOW()), (2, 145, NOW()), (2, 146, NOW()), (2, 147, NOW()), (2, 148, NOW()), (2, 149, NOW());
