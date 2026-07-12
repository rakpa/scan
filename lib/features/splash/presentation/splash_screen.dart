import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/stitch_assets.dart';
import '../../../core/design/stitch_screens.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Splash — native layout (no WebView), preloads home, fades to main.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minSplash = Duration(milliseconds: 1100);

  late final AnimationController _fadeOut;
  var _navigating = false;

  @override
  void initState() {
    super.initState();
    _fadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _fadeOut.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    final storeFuture = ref.read(onboardingStoreProvider.future);
    final preloadFuture = rootBundle.loadString(StitchScreens.dashboard);
    final store = await storeFuture;
    await preloadFuture;

    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }
    if (!mounted || _navigating) return;

    _navigating = true;
    await _fadeOut.forward();
    if (!mounted) return;

    context.go(store.isComplete ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final splashBg = AppPalette.lightTokens.splashBackground;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: splashBg,
      ),
      child: Scaffold(
        backgroundColor: splashBg,
        body: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: _fadeOut, curve: Curves.easeOut),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Image.asset(
                  StitchAssets.splashIcon,
                  width: 88,
                  height: 88,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.document_scanner_outlined,
                    size: 88,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scanella',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan · Organize · Share',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
