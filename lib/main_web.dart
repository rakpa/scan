import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme/app_theme.dart';
import 'core/design/stitch_assets.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/paywall/presentation/paywall_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'shared/widgets/stitch/stitch_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    GoRoute(path: '/home', builder: (c, s) => const _WebMainShell()),
  ],
);

/// Web-only dashboard preview — Stitch PNGs, no native DB/scan imports.
class _WebMainShell extends StatefulWidget {
  const _WebMainShell();

  @override
  State<_WebMainShell> createState() => _WebMainShellState();
}

class _WebMainShellState extends State<_WebMainShell> {
  int _tab = 0;

  String get _asset => _tab == 3 ? StitchAssets.settings : StitchAssets.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StitchFrame(
        asset: _asset,
        backgroundColor: const Color(0xFFF5F5F7),
        hotspots: [
          StitchHotspot(
            left: 0.72,
            top: 0.78,
            width: 0.22,
            height: 0.12,
            semanticLabel: 'Scan',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scanning runs on the installed app.')),
            ),
          ),
          for (var i = 0; i < 4; i++)
            StitchHotspot(
              left: 0.02 + i * 0.24,
              top: 0.905,
              width: 0.22,
              height: 0.09,
              onTap: () => setState(() => _tab = i),
            ),
        ],
      ),
    );
  }
}

class _WebPreviewApp extends StatelessWidget {
  const _WebPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ScanMaster AI preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _webRouter,
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFF1a1a1a),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: AspectRatio(
                aspectRatio: 780 / 1768,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
