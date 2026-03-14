import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_user.dart';

/// Client pentru API backend FitLingo – toată autentificarea pe server.
class ApiClient {
  ApiClient._();

  static String get _base => apiBaseUrl;

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    return _handleAuthResponse(resp);
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return _handleAuthResponse(resp);
  }

  static Future<AuthResponse> googleAuth(String idToken) async {
    final resp = await http.post(
      Uri.parse('$_base/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    return _handleAuthResponse(resp);
  }

  /// Progres gamification (level, XP, gems, streak, quests completate, achievements).
  static Future<ProgressResponse?> getProgress(String token) async {
    final resp = await http.get(
      Uri.parse('$_base/gamification/progress'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>?;
    if (body == null) return null;
    return ProgressResponse(
      userId: (body['user_id'] as num).toInt(),
      level: (body['level'] as num?)?.toInt() ?? 1,
      xp: (body['xp'] as num?)?.toInt() ?? 0,
      totalXp: (body['total_xp'] as num?)?.toInt() ?? 0,
      xpForNext: (body['xp_for_next'] as num?)?.toInt() ?? 35,
      gems: (body['gems'] as num?)?.toInt() ?? 0,
      streakDays: (body['streak_days'] as num?)?.toInt() ?? 0,
      updatedAt: body['updated_at'] as String? ?? '',
      completedQuestIds: (body['completed_quest_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      unlockedAchievements:
          (body['unlocked_achievements'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Înregistrează completarea unui quest pe server (XP, gems, achievements).
  static Future<CompleteQuestResponse?> completeQuest(
    String token, {
    required int questId,
    required String exerciseType,
    required int repsCompleted,
    String difficulty = 'beginner',
  }) async {
    final resp = await http.post(
      Uri.parse('$_base/gamification/complete-quest'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'quest_id': questId,
        'exercise_type': exerciseType,
        'reps_completed': repsCompleted,
        'difficulty': difficulty,
      }),
    );
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>?;
    if (body == null) return null;
    return CompleteQuestResponse(
      level: (body['level'] as num?)?.toInt() ?? 1,
      xp: (body['xp'] as num?)?.toInt() ?? 0,
      totalXp: (body['total_xp'] as num?)?.toInt() ?? 0,
      xpForNext: (body['xp_for_next'] as num?)?.toInt() ?? 35,
      gems: (body['gems'] as num?)?.toInt() ?? 0,
      streakDays: (body['streak_days'] as num?)?.toInt() ?? 0,
      updatedAt: body['updated_at'] as String?,
      xpEarned: (body['xp_earned'] as num?)?.toInt() ?? 0,
      gemsEarned: (body['gems_earned'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returnează utilizatorul curent din token (GET /auth/me).
  static Future<AppUser?> getMe(String token) async {
    final resp = await http.get(
      Uri.parse('$_base/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body) as Map<String, dynamic>?;
    if (body == null) return null;
    return AppUser(
      id: body['id'] as int,
      name: body['name'] as String,
      email: body['email'] as String,
      passwordHash: '',
      authProvider: body['auth_provider'] as String,
      googleId: null,
      createdAt: body['created_at'] as String? ?? '',
    );
  }

  static AuthResponse _handleAuthResponse(http.Response resp) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>?;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final user = body!['user'] as Map<String, dynamic>;
      return AuthResponse(
        accessToken: body['access_token'] as String,
        user: AppUser(
          id: user['id'] as int,
          name: user['name'] as String,
          email: user['email'] as String,
          passwordHash: '',
          authProvider: user['auth_provider'] as String,
          googleId: null,
          createdAt: user['created_at'] as String? ?? '',
        ),
      );
    }
    final detail = body?['detail'] ?? 'Request failed';
    throw Exception(detail is String ? detail : detail.toString());
  }
}

class AuthResponse {
  final String accessToken;
  final AppUser user;

  AuthResponse({required this.accessToken, required this.user});
}

class ProgressResponse {
  final int userId;
  final int level;
  final int xp;
  final int totalXp;
  final int xpForNext;
  final int gems;
  final int streakDays;
  final String updatedAt;
  final List<int> completedQuestIds;
  final List<String> unlockedAchievements;

  ProgressResponse({
    required this.userId,
    required this.level,
    required this.xp,
    required this.totalXp,
    required this.xpForNext,
    required this.gems,
    required this.streakDays,
    required this.updatedAt,
    required this.completedQuestIds,
    required this.unlockedAchievements,
  });
}

class CompleteQuestResponse {
  final int level;
  final int xp;
  final int totalXp;
  final int xpForNext;
  final int gems;
  final int streakDays;
  final String? updatedAt;
  final int xpEarned;
  final int gemsEarned;

  CompleteQuestResponse({
    required this.level,
    required this.xp,
    required this.totalXp,
    required this.xpForNext,
    required this.gems,
    required this.streakDays,
    this.updatedAt,
    required this.xpEarned,
    required this.gemsEarned,
  });
}
