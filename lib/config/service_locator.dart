import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_preference.dart';

/// Global [GetIt.instance].
final GetIt serviceLocator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  // SharedPreferences for local storage
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerLazySingleton<UserPreference>(
    () => UserPreference(serviceLocator<SharedPreferences>()),
  );
}
