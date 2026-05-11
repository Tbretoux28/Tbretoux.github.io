import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:gym_peak/api_config.dart';
import 'package:gym_peak/login_repository.dart';
import 'package:gym_peak/workout_storage.dart';

class WorkoutRemote {
  static const Duration _timeout = Duration(seconds: 8);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  static void _throwIfBad(http.Response r, String action) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('$action failed (${r.statusCode}): ${r.body}');
    }
  }

  static Future<List<WorkoutEntry>> getAll() async {
    final username = await LoginRepository.currentUsername();
    final url = ApiConfig.workoutsList(username);
    final r = await http.get(url, headers: _headers).timeout(_timeout);
    _throwIfBad(r, 'Load workouts');
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    if (decoded is! List) {
      throw Exception('Invalid response: expected JSON array');
    }
    return decoded
        .map((e) => WorkoutEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> add(WorkoutEntry entry) async {
    final username = await LoginRepository.currentUsername();
    final url = ApiConfig.workoutsSave();
    final r = await http.post(
      url,
      headers: _headers,
      body: utf8.encode(
        jsonEncode({
          ...entry.toJson(),
          'username': username,
        }),
      ),
    ).timeout(_timeout);
    _throwIfBad(r, 'Save workout');
  }

  static Future<void> deleteById(String id) async {
    final username = await LoginRepository.currentUsername();
    final url = ApiConfig.workoutsDelete(id, username);
    final r = await http.delete(url, headers: _headers).timeout(_timeout);
    _throwIfBad(r, 'Delete workout');
  }
}
