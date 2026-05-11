import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_peak/api_config.dart';

class LoginRepository {
  static const Duration _timeout = Duration(seconds: 8);
  static const String _lastUsernameKey = 'gym_peak_last_username';
  static const String _localUsersKey = 'gym_peak_local_users_v1';

  static Future<void> createAccount({
    required String username,
    required String password,
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) {
      throw Exception('Username and password are required');
    }

    if (ApiConfig.useRemoteWorkouts) {
      final r = await http
          .post(
            ApiConfig.loginCreate(),
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'username': u, 'password': p}),
          )
          .timeout(_timeout);
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception('Create account failed (${r.statusCode}): ${r.body}');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final users = _readLocalUsers(prefs);
      if (users.containsKey(u)) {
        throw Exception('Username already exists');
      }
      users[u] = p;
      await prefs.setString(_localUsersKey, jsonEncode(users));
    }

    await setCurrentUsername(u);
  }

  static Future<void> authenticate({
    required String username,
    required String password,
  }) async {
    final u = username.trim();
    final p = password.trim();
    if (u.isEmpty || p.isEmpty) {
      throw Exception('Username and password are required');
    }

    if (ApiConfig.useRemoteWorkouts) {
      final r = await http
          .post(
            ApiConfig.loginAuth(),
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'username': u, 'password': p}),
          )
          .timeout(_timeout);
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception('Login failed (${r.statusCode}): ${r.body}');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final users = _readLocalUsers(prefs);
      final stored = users[u];
      if (stored == null || stored != p) {
        throw Exception('Invalid username or password');
      }
    }

    await setCurrentUsername(u);
  }

  static Future<void> setCurrentUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUsernameKey, username.trim());
  }

  static Future<String> currentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(_lastUsernameKey)?.trim();
    if (u == null || u.isEmpty) return 'guest';
    return u;
  }

  static Map<String, String> _readLocalUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_localUsersKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return decoded.map((k, v) => MapEntry(k, (v ?? '').toString()));
  }
}
