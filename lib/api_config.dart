/// XAMPP / MySQL live sync is **opt-in**.
///
/// Run the app with a base URL pointing at the folder you copied to `htdocs`:
///
/// **Windows / Chrome (same PC as XAMPP)**  
/// `flutter run --dart-define=WORKOUT_API_BASE=http://localhost/gym_peak_api`
///
/// **Android emulator** (Apache on your PC)  
/// `flutter run --dart-define=WORKOUT_API_BASE=http://10.0.2.2/gym_peak_api`
///
/// **Physical phone** (same Wi‑Fi as PC; use your PC’s LAN IP)  
/// `flutter run --dart-define=WORKOUT_API_BASE=http://192.168.1.50/gym_peak_api`
///
/// If `WORKOUT_API_BASE` is **empty**, workouts stay on the device (`shared_preferences`).
abstract class ApiConfig {
  static const String workoutApiBase = String.fromEnvironment('WORKOUT_API_BASE');

  static bool get useRemoteWorkouts => workoutApiBase.isNotEmpty;

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = workoutApiBase.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base/$path').replace(queryParameters: query);
  }

  static Uri workoutsList(String username) =>
      _uri('workouts_list.php', {'username': username});

  static Uri workoutsSave() => _uri('workouts_save.php');

  static Uri workoutsDelete(String id, String username) =>
      _uri('workouts_delete.php', {'id': id, 'username': username});

  static Uri loginCreate() => _uri('login_create.php');

  static Uri loginAuth() => _uri('login_auth.php');
}
