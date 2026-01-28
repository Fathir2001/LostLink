import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/env_config.dart';
import 'core/services/notification_service.dart';
import 'core/providers/theme_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize push notifications (skip on web)
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification service initialization skipped: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Provider overrides
  final overrides = [
    sharedPreferencesProvider.overrideWithValue(sharedPreferences),
  ];

  // Initialize Sentry for crash reporting (optional)
  if (EnvConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvConfig.sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment = EnvConfig.environment;
      },
      appRunner: () => runApp(
        ProviderScope(overrides: overrides, child: const LostLinkApp()),
      ),
    );
  } else {
    runApp(ProviderScope(overrides: overrides, child: const LostLinkApp()));
  }
}
