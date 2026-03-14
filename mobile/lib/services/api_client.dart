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
