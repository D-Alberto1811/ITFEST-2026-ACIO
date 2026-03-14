import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/app_user.dart';
import 'api_client.dart';

/// Serviciu de autentificare – comunică exclusiv cu backend-ul.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: googleServerClientId,
    scopes: <String>['email'],
  );

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
    await _saveSession(res);
    return res.user;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.login(
      email: email.trim(),
      password: password,
    );
    await _saveSession(res);
    return res.user;
  }

  Future<AppUser> signInWithGoogle() async {
    try {
      if (googleServerClientId == null || googleServerClientId!.isEmpty) {
        throw Exception(
          'googleServerClientId lipsește în api_config.dart. '
          'Creează Web OAuth client în Google Cloud Console și adaugă-l acolo.',
        );
      }
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled.');
      }

      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google sign-in: id_token not available. Add serverClientId (Web OAuth client) in api_config.dart.',
        );
      }

      final res = await ApiClient.googleAuth(idToken);
      await _saveSession(res);
      return res.user;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('logged_in_user_id');
    await prefs.remove('auth_token');
    await prefs.remove('cached_user');

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> _saveSession(AuthResponse res) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setInt('logged_in_user_id', res.user.id!);
    await prefs.setString('auth_token', res.accessToken);
    await prefs.setString('cached_user', jsonEncode(res.user.toMap()));
  }

  Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_logged_in') != true) return null;
    return prefs.getInt('logged_in_user_id');
  }

  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return null;

    final cached = prefs.getString('cached_user');
    if (cached != null) {
      try {
        return AppUser.fromMap(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
      } catch (_) {}
    }

    final user = await ApiClient.getMe(token);
    if (user != null) {
      await prefs.setString('cached_user', jsonEncode(user.toMap()));
      return user;
    }

    await logout();
    return null;
  }
}
