import 'package:shared_preferences/shared_preferences.dart';

class UserPreference {
  final SharedPreferences prefs;
  UserPreference(this.prefs);

  static const String _keyUserName = "user_name";
  static const String _keyCampusName = "campus_name";
  static const String _keyIsSetupCompleted = "is_setup_completed";

  Future<void> saveUserProfile({
    required String name,
    required String campus,
  }) async {
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyCampusName, campus);
    await prefs.setBool(_keyIsSetupCompleted, true);
  }

  String? getUserName() => prefs.getString(_keyUserName);
  String? getCampusName() => prefs.getString(_keyCampusName);
  bool isSetupCompleted() => prefs.getBool(_keyIsSetupCompleted) ?? false;

  Future<void> clearData() async {
    await prefs.clear();
  }
}
