import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme/app_theme.dart';
import 'features/home/presentation/web_home_preview.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/paywall/presentation/paywall_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

/// Web-only entry point for previewing the design (splash â†’ onboarding â†’
/// paywall â†’ home layout) in a browser.
///
/// It deliberately avoids the native, DB-backed routes (real home, document
/// detail, enhance) which depend on `dart:io`/drift and can't compile for web.
/// Run with: flutter run -d web-server -t lib/main_web.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Preview-only: reset onboarding each load so a reload always shows the full
  // startup flow (splash â†’ onboarding â†’ paywall â†’ home).
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  runApp(const ProviderScope(child: _WebPreviewApp()));
}

final _webRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/paywall', builder: (c, s) => const PaywallScreen()),
    GoRoute(path: '/home', builder: (c, s) => const WebHomePreview()),
  ],
);

class _WebPreviewApp extends StatelessWidget {
  const _WebPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Scanella preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _webRouter,
    );
  }
}

