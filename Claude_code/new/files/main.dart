import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Single canonical import — removed the duplicate `../firebase_options.dart`
import 'package:uiux/firebase_options.dart';

import 'app/app.dart';
import 'core/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge black status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // ── Firebase ─────────────────────────────────────────────────────────────
  // For Android/iOS: run `flutterfire configure` and uncomment the platform
  // case in firebase_options.dart. The try/catch lets the app run on
  // unsupported platforms (Linux, etc.) without crashing.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialised successfully.');
  } on UnsupportedError catch (e) {
    // Platform not configured in firebase_options.dart yet — dev-only bypass
    // still works because kEnableAuth = false in login_screen.dart.
    debugPrint('Firebase: platform not configured — $e');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // ── SharedPreferences ────────────────────────────────────────────────────
  // Must be awaited before runApp so settings are available synchronously
  // inside Riverpod providers at first frame.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Make the SharedPreferences instance available to all providers.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
