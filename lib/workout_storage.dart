import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_peak/api_config.dart';
import 'package:gym_peak/login_repository.dart';
import 'package:gym_peak/workout_remote.dart';

class WorkoutEntry {
  WorkoutEntry({
    required this.id,
    required this.type,
    required this.reps,
    required this.weight,
    required this.date,
  });

  final String id;
  final String type;
  final int reps;
  final double weight;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'reps': reps,
        'weight': weight,
        'date': date.toIso8601String(),
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final dateRaw = json['date'] as String;
    return WorkoutEntry(
      id: idRaw is int ? idRaw.toString() : idRaw as String,
      type: json['type'] as String,
      reps: (json['reps'] as num).toInt(),
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(dateRaw),
    );
  }
}

class WorkoutStorage {
  static const _keyPrefix = 'gym_peak_workouts_v1';

  static Future<List<WorkoutEntry>> getAll() async {
    if (ApiConfig.useRemoteWorkouts) {
      return WorkoutRemote.getAll();
    }
    final key = await _userKey();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WorkoutEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> add(WorkoutEntry entry) async {
    if (ApiConfig.useRemoteWorkouts) {
      await WorkoutRemote.add(entry);
      return;
    }
    final all = await getAll();
    all.add(entry);
    await _saveAll(all);
  }

  static Future<void> deleteById(String id) async {
    if (ApiConfig.useRemoteWorkouts) {
      await WorkoutRemote.deleteById(id);
      return;
    }
    final all = await getAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  static Future<void> _saveAll(List<WorkoutEntry> entries) async {
    final key = await _userKey();
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(key, encoded);
  }

  static Future<String> _userKey() async {
    final username = await LoginRepository.currentUsername();
    return '${_keyPrefix}_$username';
  }
}
