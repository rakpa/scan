import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../shared/widgets/stitch/stitch_frame.dart';
import '../../onboarding/data/onboarding_store.dart';

/// Paywall — Stitch Premium Dashboard PNG; tap bottom to continue.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final store = await ref.read(onboardingStoreProvider.future);
    await store.markComplete();
    await store.unlockPremium();
    if (context.mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: StitchFrame(
        asset: StitchAssets.premiumDashboard,
        backgroundColor: const Color(0xFFF5F5F7),
        hotspots: [
          StitchHotspot(
            left: 0.05,
            top: 0.02,
            width: 0.15,
            height: 0.08,
            semanticLabel: 'Close',
            onTap: () => _finish(context, ref),
          ),
          StitchHotspot(
            left: 0.1,
            top: 0.85,
            width: 0.8,
            height: 0.1,
            semanticLabel: 'Start trial',
            onTap: () => _finish(context, ref),
          ),
        ],
      ),
    );
  }
}
