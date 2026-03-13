import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'database_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );

  Future<String> _hashPassword(String password) async {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim();

    final existingUser =
        await DatabaseService.instance.getUserByEmail(normalizedEmail);

    if (existingUser != null) {
      throw Exception('An account with this email already exists.');
    }

    final passwordHash = await _hashPassword(password);
    final now = DateTime.now().toIso8601String();

    final user = AppUser(
      name: normalizedName,
      email: normalizedEmail,
      passwordHash: passwordHash,
      authProvider: 'local',
      googleId: null,
      createdAt: now,
    );

    final userId = await DatabaseService.instance.insertUser(user);
    final createdUser = user.copyWith(id: userId);

    await _saveSession(createdUser.id!);

    return createdUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final user = await DatabaseService.instance.getUserByEmail(normalizedEmail);

    if (user == null) {
      throw Exception('No account found for this email.');
    }

    if (user.authProvider == 'google') {
      throw Exception(
        'This account uses Google sign-in. Please use Login with Google.',
      );
    }

    final passwordHash = await _hashPassword(password);

    if (user.passwordHash != passwordHash) {
      throw Exception('Incorrect password.');
    }

    await _saveSession(user.id!);

    return user;
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final existingByGoogleId =
          await DatabaseService.instance.getUserByGoogleId(googleUser.id);

      if (existingByGoogleId != null) {
        await _saveSession(existingByGoogleId.id!);
        return existingByGoogleId;
      }

      final normalizedEmail = googleUser.email.trim().toLowerCase();
      final existingByEmail =
          await DatabaseService.instance.getUserByEmail(normalizedEmail);

      if (existingByEmail != null) {
        final updatedUser = existingByEmail.copyWith(
          authProvider: 'google',
          googleId: googleUser.id,
        );

        await DatabaseService.instance.updateUser(updatedUser);
        await _saveSession(updatedUser.id!);

        return updatedUser;
      }

      final now = DateTime.now().toIso8601String();

      final newUser = AppUser(
        name: (googleUser.displayName != null &&
                googleUser.displayName!.trim().isNotEmpty)
            ? googleUser.displayName!.trim()
            : 'Google User',
        email: normalizedEmail,
        passwordHash: '',
        authProvider: 'google',
        googleId: googleUser.id,
        createdAt: now,
      );

      final userId = await DatabaseService.instance.insertUser(newUser);
      final createdUser = newUser.copyWith(id: userId);

      await _saveSession(createdUser.id!);

      return createdUser;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('is_logged_in');
    await prefs.remove('logged_in_user_id');

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('logged_in_user_id', userId);
  }

  Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) {
      return null;
    }

    return prefs.getInt('logged_in_user_id');
  }

  Future<AppUser?> getCurrentUser() async {
    final userId = await getLoggedInUserId();

    if (userId == null) {
      return null;
    }

    return DatabaseService.instance.getUserById(userId);
  }
}