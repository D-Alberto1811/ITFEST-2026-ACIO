import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import '../models/player_progress.dart';
import 'database_service.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  final DatabaseService _database = DatabaseService.instance;

  Future<void> initialize() async {
    await _database.initialize();
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _database.getUserByEmail(normalizedEmail);

    if (existing != null) {
      throw Exception('An account with this email already exists.');
    }

    final user = AppUser(
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: _hashPassword(password),
      authProvider: 'local',
      googleId: null,
      createdAt: DateTime.now().toIso8601String(),
    );

    final id = await _database.insertUser(user);
    final createdUser = user.copyWith(id: id);

    await _database.upsertPlayerProgress(PlayerProgress.initial(id));

    return createdUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await _database.getUserByEmail(normalizedEmail);

    if (user == null) {
      throw Exception('No account found for this email.');
    }

    final passwordHash = _hashPassword(password);

    if (user.passwordHash != passwordHash) {
      throw Exception('Invalid password.');
    }

    final progress = await _database.getPlayerProgress(user.id!);
    if (progress == null) {
      await _database.upsertPlayerProgress(PlayerProgress.initial(user.id!));
    }

    return user;
  }

  Future<AppUser?> getUserById(int id) async {
    return _database.getUserById(id);
  }

  Future<PlayerProgress> getOrCreateProgress(int userId) async {
    final existing = await _database.getPlayerProgress(userId);
    if (existing != null) {
      return existing;
    }

    final initial = PlayerProgress.initial(userId);
    await _database.upsertPlayerProgress(initial);
    return initial;
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    await _database.upsertPlayerProgress(
      progress.copyWith(updatedAt: DateTime.now().toIso8601String()),
    );
  }

  Future<Set<int>> getCompletedQuestIds(int userId) async {
    return _database.getCompletedQuestIds(userId);
  }

  Future<void> markQuestCompleted(int userId, int questId) async {
    await _database.markQuestCompleted(userId, questId);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}