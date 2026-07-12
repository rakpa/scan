import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../shared/widgets/stitch/stitch_frame.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Splash — Stitch logo PNG on navy canvas.
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
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    context.go(store.isComplete ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001847),
      body: StitchFrame(
        asset: StitchAssets.logo,
        backgroundColor: const Color(0xFF001847),
        fit: BoxFit.contain,
      )
    );
  }
}
