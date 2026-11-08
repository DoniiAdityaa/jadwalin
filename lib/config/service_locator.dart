import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/chat_dao.dart';
import '../data/local/database_helper.dart';
import '../data/local/schedule_dao.dart';
import '../data/local/user_memory_dao.dart';
import '../data/service/ai_chat_service.dart';
import 'user_preference.dart';

/// Global [GetIt.instance].
final GetIt serviceLocator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  // SharedPreferences for local storage (preferensi sederhana)
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<SharedPreferences>(prefs);
  serviceLocator.registerLazySingleton<UserPreference>(
    () => UserPreference(serviceLocator<SharedPreferences>()),
  );

  // SQLite Helper & DAOs (data relasional lokal)
  serviceLocator.registerLazySingleton<DatabaseHelper>(
    () => DatabaseHelper.instance,
  );
  serviceLocator.registerLazySingleton<ScheduleDao>(
    () => ScheduleDao(dbHelper: serviceLocator<DatabaseHelper>()),
  );
  serviceLocator.registerLazySingleton<ChatDao>(
    () => ChatDao(dbHelper: serviceLocator<DatabaseHelper>()),
  );
  serviceLocator.registerLazySingleton<UserMemoryDao>(
    () => UserMemoryDao(dbHelper: serviceLocator<DatabaseHelper>()),
  );

  // Seed contoh jadwal sekali di instalasi pertama.
  await serviceLocator<DatabaseHelper>().seedSampleSchedulesOnce(prefs);

  // AI Service (Dattio / OpenAI-compatible)
  serviceLocator.registerLazySingleton<AiChatService>(
    () => AiChatService(),
  );
}
