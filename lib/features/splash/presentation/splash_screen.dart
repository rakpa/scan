import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Splash — original Stitch HTML export.
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
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    context.go(store.isComplete ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001847),
      body: StitchHtmlView(
        htmlAsset: StitchScreens.splash,
        backgroundColor: const Color(0xFF001847),
        interactive: false,
      ),
    );
  }
}
