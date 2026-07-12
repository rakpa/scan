import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/app_spacing.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Launch screen matching Stitch "Splash Screen" — deep navy gradient with logo.
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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF001847),
              Color(0xFF002020),
              Color(0xFF001F2A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: BrandColors.primary.withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.primaryContainer.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: AppDuration.base)
                  .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'ScanMaster AI',
                style: context.text.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: AppDuration.base),
            ],
          ),
        ),
      ),
    );
  }
}
