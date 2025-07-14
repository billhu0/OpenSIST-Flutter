import 'package:flutter/material.dart';
import 'package:opensist_alpha/models.dart';
import 'package:opensist_alpha/opensist_applicant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opensist_alpha/opensist_login.dart';
import 'package:opensist_alpha/opensist_programs.dart';
import 'opensist_program.dart';
import 'package:opensist_alpha/page_home.dart';
import 'package:opensist_alpha/page_settings.dart';

import 'opensist_applicants.dart';
import 'opensist_datapoints.dart';

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
                '/': (context) => const MyHomePage(title: 'OpenSIST'),
                '/settings': (context) => const SettingsPage(),
                '/opensist_login': (context) => const LoginPage(),
                '/opensist_programs': (context) => const ProgramsPage(),
                '/opensist_datapoints': (context) => const DatapointsPage(),
                '/opensist_applicants': (context) => const ApplicantsPage(),
              },
              onGenerateRoute: (settings) {
                if (settings.name == '/opensist_applicant') {
                  if (settings.arguments is String) {
                    return MaterialPageRoute(
                      builder: (context) => ApplicantPage(applicantId: settings.arguments as String),
                    );
                  }
                  else if (settings.arguments is Applicant) {
                    return MaterialPageRoute(
                      builder: (context) => ApplicantPage(
                        applicantId: (settings.arguments as Applicant).applicantID,
                        applicant: settings.arguments as Applicant,
                      ),
                    );
                  }
                }
                else if (settings.name == '/opensist_program') {
                  if (settings.arguments is ProgramData) {
                    return MaterialPageRoute(
                      builder: (context) => ProgramPage(
                        programName: (settings.arguments as ProgramData).ProgramID,
                        program: settings.arguments as ProgramData,
                      )
                    );
                  } else if (settings.arguments is String) {
                    return MaterialPageRoute(
                      builder: (context) => ProgramPage(
                        programName: settings.arguments as String,
                        program: null, // ProgramData will be fetched in initState
                      ),
                    );
                  }
                }
                // Handle unknown routes gracefully
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Unknown Route')),
                    body: Center(child: Text('No route defined for ${settings.name}')),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
