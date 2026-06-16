import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/analytics_providers.dart';
import 'core/providers/app_locale_provider.dart';
import 'core/providers/app_theme_mode_provider.dart';
import 'core/providers/connectivity_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'presentation/providers/bookmark_providers.dart';
import 'presentation/providers/user_providers.dart';
import 'shared/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Resolve SharedPreferences eagerly so the locale + theme providers can
  // read the saved values synchronously when the first widget builds — no
  // flash of default settings before the saved values load.
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const TabeminaApp(),
    ),
  );
}

class TabeminaApp extends ConsumerWidget {
  const TabeminaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appThemeModeProvider);
    // Side-effect providers — touch them so they activate on app start and
    // run on every auth-state change. The user-profile-sync mirrors the
    // signed-in account into `users/{uid}`; the bookmark migration moves
    // guest-era SharedPreferences entries into Firestore on first sign-in.
    ref.watch(userProfileSyncProvider);
    ref.watch(bookmarkMigrationProvider);
    // Plumbing sanity check: fire a single `app_start` event so we can confirm
    // the AnalyticsService → FirebaseAnalytics pipe is connected on launch.
    ref.watch(appStartAnalyticsProvider);
    return MaterialApp.router(
      title: 'Tabemina',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: flutterThemeModeFor(mode),
      routerConfig: ref.watch(routerProvider),
      // Ambient, app-wide offline banner (B-3-2) pinned above every screen's
      // app bar. Display-only — see [OfflineBanner].
      builder: (context, child) =>
          _AppChrome(child: child ?? const SizedBox.shrink()),
    );
  }
}

/// App-wide chrome wrapped around the router output: the offline banner on top,
/// the navigator below. When the banner is showing it fills the status-bar
/// inset itself, so the inset is stripped from the app below to avoid
/// double-padding (the whole app reflows down by the banner's height).
class _AppChrome extends ConsumerWidget {
  const _AppChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(connectivityStatusProvider).asData?.value ==
        NetworkStatus.offline;

    return Column(
      children: [
        const OfflineBanner(),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: isOffline,
            child: child,
          ),
        ),
      ],
    );
  }
}
