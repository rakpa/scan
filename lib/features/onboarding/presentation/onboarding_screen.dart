import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Onboarding — sequential Stitch HTML screens (Auto-Crop → Export).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == StitchScreens.onboardingFlow.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      context.go('/paywall');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _skip() async {
    final store = await ref.read(onboardingStoreProvider.future);
    await store.markComplete();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _controller,
        onPageChanged: (i) => setState(() => _index = i),
        itemCount: StitchScreens.onboardingFlow.length,
        itemBuilder: (context, i) => StitchHtmlView(
          htmlAsset: StitchScreens.onboardingFlow[i],
          backgroundColor: Colors.white,
          interactive: false,
          hotspots: [
            StitchHotspot(
              left: 0.05,
              top: 0.82,
              width: 0.9,
              height: 0.08,
              semanticLabel: 'Next',
              onTap: _next,
            ),
            StitchHotspot(
              left: 0.2,
              top: 0.9,
              width: 0.6,
              height: 0.06,
              semanticLabel: 'Skip',
              onTap: _skip,
            ),
          ],
        ),
      ),
    );
  }
}
