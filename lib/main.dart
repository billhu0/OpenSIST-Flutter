import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opensist_alpha/opensist_login.dart';
import 'package:opensist_alpha/opensist_programs.dart';
import 'package:opensist_alpha/page_home.dart';
import 'package:opensist_alpha/page_settings.dart';

// Top‐level notifiers that the whole app listens to:
final seedColorNotifier = ValueNotifier<Color>(Colors.blueAccent);
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Load saved accent‐color (stored as int) or default to blueAccent
  seedColorNotifier.value = Color(
    prefs.getInt('seedColor') ?? Colors.blueAccent.value,
  );

  // Load saved themeMode index or default to system
  themeModeNotifier.value = ThemeMode.values[
    prefs.getInt('themeMode') ?? ThemeMode.system.index
  ];

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Rebuild when either notifier changes:
    return ValueListenableBuilder<Color>(
      valueListenable: seedColorNotifier,
      builder: (context, seedColor, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (context, themeMode, __) {
            return MaterialApp(
              title: 'Flutter Demo',
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: seedColor,
                  brightness: Brightness.dark,
                ),
                useMaterial3: true,
              ),
              themeMode: themeMode,
              initialRoute: '/',
              routes: {
                '/': (context) => const MyHomePage(title: 'My Flutter App'),
                '/settings': (context) => const SettingsPage(),
                '/opensist_login': (context) => const LoginPage(),
                '/opensist_program': (context) => const ProgramsPage(),
              },
            );
          },
        );
      },
    );
  }
}
