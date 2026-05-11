import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  UserProfile({
    required this.displayName,
    required this.email,
    required this.fitnessGoal,
    required this.height,
    required this.weight,
    required this.preferredUnit,
    this.memberSinceIso,
  });

  final String displayName;
  final String email;
  final String fitnessGoal;
  final String height;
  final String weight;
  final String preferredUnit;
  /// First time profile was saved (shown as "Member since").
  final String? memberSinceIso;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'fitnessGoal': fitnessGoal,
        'height': height,
        'weight': weight,
        'preferredUnit': preferredUnit,
        'memberSinceIso': memberSinceIso,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fitnessGoal: json['fitnessGoal'] as String? ?? '',
      height: json['height'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      preferredUnit: json['preferredUnit'] as String? ?? 'lb',
      memberSinceIso: json['memberSinceIso'] as String?,
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? fitnessGoal,
    String? height,
    String? weight,
    String? preferredUnit,
    String? memberSinceIso,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      preferredUnit: preferredUnit ?? this.preferredUnit,
      memberSinceIso: memberSinceIso ?? this.memberSinceIso,
    );
  }
}

class ProfileStorage {
  static const _keyPrefix = 'gym_peak_profile_v1';
  static const _lastUsernameKey = 'gym_peak_last_username';

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsername = prefs.getString(_lastUsernameKey)?.trim();
    final key = _profileKey(lastUsername);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return UserProfile(
        displayName: (lastUsername != null && lastUsername.isNotEmpty)
            ? lastUsername
            : 'Gym Peak member',
        email: '',
        fitnessGoal: '',
        height: '',
        weight: '',
        preferredUnit: 'lb',
        memberSinceIso: null,
      );
    }
    final profile = UserProfile.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    if (lastUsername != null && lastUsername.isNotEmpty) {
      return profile.copyWith(displayName: lastUsername);
    }
    return profile;
  }

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsername = prefs.getString(_lastUsernameKey)?.trim();
    final key = _profileKey(lastUsername);
    final hadStoredProfile = prefs.getString(key) != null;
    var toSave = profile;
    if (!hadStoredProfile && toSave.memberSinceIso == null) {
      toSave = toSave.copyWith(
        memberSinceIso: DateTime.now().toIso8601String(),
      );
    }
    await prefs.setString(key, jsonEncode(toSave.toJson()));
  }

  static String _profileKey(String? username) {
    final user = (username == null || username.isEmpty) ? 'guest' : username;
    return '${_keyPrefix}_$user';
  }
}
