import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/theme/app_theme.dart';
import 'core/design/stitch_assets.dart';
import 'core/design/stitch_screens.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/paywall/presentation/paywall_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'shared/widgets/stitch/stitch_html_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureStitchWebViewInitialized();
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
    GoRoute(
      path: '/document/demo',
      builder: (c, s) => const _WebDocumentDemo(),
    ),
    GoRoute(
      path: '/document/demo/enhance',
      builder: (c, s) => const _WebEnhanceDemo(),
    ),
  ],
);

class _WebMainShell extends StatefulWidget {
  const _WebMainShell();

  @override
  State<_WebMainShell> createState() => _WebMainShellState();
}

class _WebMainShellState extends State<_WebMainShell> {
  int _tab = 0;
  bool _scanning = false;
  bool _premium = false;

  String get _html => switch (_tab) {
        3 => StitchScreens.settings,
        _ => StitchScreens.dashboard,
      };

  Future<void> _scan() async {
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _scanning = false);
    context.push('/document/demo');
  }

  @override
  Widget build(BuildContext context) {
    if (_scanning) {
      return Scaffold(
        body: StitchHtmlView(
          htmlAsset: StitchScreens.smartCaptureFor(premium: _premium),
          backgroundColor: Colors.black,
          interactive: false,
        ),
      );
    }

    return Scaffold(
      body: StitchHtmlView(
        htmlAsset: _html,
        backgroundColor: const Color(0xFFF5F5F7),
        interactive: _tab != 3,
        hotspots: [
          if (_tab <= 1)
            StitchHotspot(
              left: 0.72,
              top: 0.78,
              width: 0.22,
              height: 0.12,
              semanticLabel: 'Scan',
              onTap: _scan,
            ),
          for (var i = 0; i < 4; i++)
            StitchHotspot(
              left: 0.02 + i * 0.24,
              top: 0.905,
              width: 0.22,
              height: 0.09,
              onTap: () => setState(() => _tab = i),
            ),
          if (_tab == 0)
            StitchHotspot(
              left: 0.82,
              top: 0.045,
              width: 0.14,
              height: 0.07,
              semanticLabel: 'Settings',
              onTap: () => setState(() => _tab = 3),
            ),
          if (_tab == 3)
            StitchHotspot(
              left: 0.05,
              top: 0.12,
              width: 0.9,
              height: 0.12,
              semanticLabel: 'Unlock premium',
              onTap: () => setState(() => _premium = true),
            ),
        ],
      ),
    );
  }
}

class _WebDocumentDemo extends StatefulWidget {
  const _WebDocumentDemo();

  @override
  State<_WebDocumentDemo> createState() => _WebDocumentDemoState();
}

class _WebDocumentDemoState extends State<_WebDocumentDemo> {
  bool _appending = false;

  Future<void> _addPage() async {
    setState(() => _appending = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _appending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          StitchHtmlView(
            htmlAsset: StitchScreens.premiumDocumentExport,
            backgroundColor: const Color(0xFFF9F9FB),
            interactive: false,
            hotspots: [
              StitchHotspot(
                left: 0.02,
                top: 0.04,
                width: 0.12,
                height: 0.07,
                semanticLabel: 'Back',
                onTap: () => context.pop(),
              ),
              StitchHotspot(
                left: 0.02,
                top: 0.88,
                width: 0.18,
                height: 0.1,
                semanticLabel: 'Add page',
                onTap: _addPage,
              ),
              StitchHotspot(
                left: 0.22,
                top: 0.88,
                width: 0.18,
                height: 0.1,
                semanticLabel: 'Enhance',
                onTap: () => context.push('/document/demo/enhance'),
              ),
              StitchHotspot(
                left: 0.32,
                top: 0.86,
                width: 0.36,
                height: 0.12,
                semanticLabel: 'Export PDF',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export runs on the installed app.')),
                ),
              ),
            ],
          ),
          if (_appending)
            StitchHtmlView(
              htmlAsset: StitchScreens.perspectiveCrop,
              backgroundColor: Colors.black87,
              interactive: false,
            ),
        ],
      ),
    );
  }
}

class _WebEnhanceDemo extends StatelessWidget {
  const _WebEnhanceDemo();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StitchHtmlView(
        htmlAsset: StitchScreens.filterEnhance,
        backgroundColor: const Color(0xFFF9F9FB),
        interactive: false,
        hotspots: [
          StitchHotspot(
            left: 0.02,
            top: 0.04,
            width: 0.12,
            height: 0.07,
            semanticLabel: 'Cancel',
            onTap: () => context.pop(),
          ),
          StitchHotspot(
            left: 0.78,
            top: 0.04,
            width: 0.18,
            height: 0.07,
            semanticLabel: 'Done',
            onTap: () => context.pop(),
          ),
          for (var i = 0; i < 5; i++)
            StitchHotspot(
              left: 0.06 + i * 0.17,
              top: 0.72,
              width: 0.14,
              height: 0.14,
              semanticLabel: 'Filter $i',
              onTap: () {},
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
        final size = MediaQuery.sizeOf(context);
        // Fill most of the browser window — not a tiny 390px mockup.
        final frameHeight = (size.height * 0.92).clamp(640.0, 920.0);
        final frameWidth = frameHeight * (StitchScreens.designWidth / StitchScreens.designHeight);

        return ColoredBox(
          color: const Color(0xFF1a1a1a),
          child: Center(
            child: SizedBox(
              width: frameWidth,
              height: frameHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
