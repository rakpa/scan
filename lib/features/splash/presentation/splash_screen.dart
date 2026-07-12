import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Launch screen: solid dark-purple with the logo mark, matching the native
/// Android-12 splash so the brand appears immediately with no flash.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = await ref.read(onboardingStoreProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    context.go(store.isComplete ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.splashBackground,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogoMark(size: 116)
                    .animate()
                    .fadeIn(duration: AppDuration.base)
                    .moveY(begin: 10, end: 0, curve: Curves.easeOut),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Scanella',
                  style: context.text.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: AppDuration.base),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'PDF Scanner & Maker',
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ).animate().fadeIn(delay: 280.ms),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.xxl,
            child: Center(
              child: Text(
                'V 0.1',
                style: context.text.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ).animate().fadeIn(delay: 450.ms),
            ),
          ),
        ],
      ),
    );
  }
}

