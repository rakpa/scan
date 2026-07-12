import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../shared/widgets/stitch/stitch_frame.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Onboarding — sequential Stitch PNGs 02→06 (Auto-Crop through Export).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == StitchAssets.onboardingFlow.length - 1;

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: StitchAssets.onboardingFlow.length,
            itemBuilder: (context, i) => StitchFrame(
              asset: StitchAssets.onboardingFlow[i],
              backgroundColor: Colors.white,
            ),
          ),
          // Next button region (bottom center — matches Stitch onboarding)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.sizeOf(context).height * 0.14,
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: _next),
            ),
          ),
          // Skip link region (above Next)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.sizeOf(context).height * 0.14,
            height: MediaQuery.sizeOf(context).height * 0.06,
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: _skip),
            ),
          ),
        ],
      ),
    );
  }
}
