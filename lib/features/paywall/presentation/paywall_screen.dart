import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/neu_decorations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';
import '../../onboarding/data/onboarding_store.dart';

enum _Plan { monthly, annual }

/// Subscription screen — Stitch Settings subscription styling.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  _Plan _plan = _Plan.monthly;

  Future<void> _finishToHome() async {
    final store = await ref.read(onboardingStoreProvider.future);
    await store.markComplete();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.canvasBackground,
      body: SafeArea(
        child: Column(
          children: [
            StitchTransactionalHeader(
              title: 'ScanMaster AI Pro',
              onBack: _finishToHome,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: NeuDecorations.card(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            size: 48, color: context.colors.primary),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Unlock Premium',
                            style: context.text.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Unlimited scans, high-quality PDF export, batch scanning, and no watermarks.',
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _FeatureRow(Icons.collections_rounded, 'Unlimited Image to PDF'),
                  _FeatureRow(Icons.high_quality_rounded, 'High-Quality PDF Export'),
                  _FeatureRow(Icons.layers_rounded, 'Batch Scanning'),
                  _FeatureRow(Icons.block_rounded, 'No Watermark'),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _PlanCard(
                          selected: _plan == _Plan.monthly,
                          badge: '3 DAYS FREE',
                          title: 'Monthly',
                          price: '₹ 399',
                          onTap: () => setState(() => _plan = _Plan.monthly),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PlanCard(
                          selected: _plan == _Plan.annual,
                          badge: 'Best Value',
                          title: 'Annual',
                          price: '₹ 1,999',
                          onTap: () => setState(() => _plan = _Plan.annual),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  PrimaryButton(
                    label: 'Start 3-Day Free Trial',
                    onPressed: _finishToHome,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _plan == _Plan.monthly
                        ? '3 days free, then ₹ 399/month'
                        : 'Billed ₹ 1,999/year',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, size: 22, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.text.titleSmall),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.selected,
    required this.badge,
    required this.title,
    required this.price,
    required this.onTap,
  });

  final bool selected;
  final String badge;
  final String title;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: NeuDecorations.flat(),
          border: Border.all(
            color: selected ? context.colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: context.text.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: context.text.titleSmall),
            Text(price,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.primary,
                )),
          ],
        ),
      ),
    );
  }
}
