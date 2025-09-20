import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:terminus/features/auth/pin_setup_screen.dart';
import 'package:terminus/features/auth/pin_unlock_screen.dart';
import 'package:terminus/features/home/home_screen.dart';
import 'package:terminus/features/location/map_screen.dart';
import 'package:terminus/features/placeholder_screen.dart';
import 'package:terminus/features/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const storage = FlutterSecureStorage();
  final isPinSet = await storage.read(key: 'isPinSet') ?? 'false';
  final String initialRoute = (isPinSet == 'true') ? '/unlock' : '/setup';
  runApp(TerminusApp(initialRoute: initialRoute));
}

class TerminusApp extends StatelessWidget {
  final String initialRoute;
  const TerminusApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project Terminus',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/setup': (context) => const PinSetupScreen(),
        '/unlock': (context) => const PinUnlockScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/fullscreen-map': (context) => const FullScreenMapScreen(),
        '/audio': (context) => const PlaceholderScreen(title: 'Audio Logs'),
        '/video': (context) => const PlaceholderScreen(title: 'Video Vault'),
        '/storage': (context) => const PlaceholderScreen(title: 'Secure Storage'),
        '/sync': (context) => const PlaceholderScreen(title: 'Cloud Sync'),
      },
    );
  }
}

