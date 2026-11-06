import 'package:flutter/material.dart';
import 'package:jadwalin/config/service_locator.dart';
import 'package:jadwalin/main_navigation.dart';
import 'package:jadwalin/ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setUpLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jadwalin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const MainNavigation(),
    );
  }
}
