import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/app_locale_provider.dart';
import 'core/providers/app_theme_mode_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Resolve SharedPreferences eagerly so the locale + theme providers can
  // read the saved values synchronously when the first widget builds — no
  // flash of default settings before the saved values load.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TabeminaApp(),
    ),
  );
}

class TabeminaApp extends ConsumerWidget {
  const TabeminaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    return MaterialApp.router(
      title: 'Tabemina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: flutterThemeModeFor(mode),
      routerConfig: appRouter,
    );
  }
}
