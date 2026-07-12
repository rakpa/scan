import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../onboarding/data/onboarding_store.dart';

enum _Plan { monthly, annual }

/// Subscription screen — UI only. No billing is wired up; the trial button and
/// close both simply complete onboarding and continue into the app.
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

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              onClose: _finishToHome,
              onRestore: () => _comingSoon('Restore'),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightCard(),
                    SizedBox(height: AppSpacing.xl),
                    Text('Trusted by 1M+ Users',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800)),
                    SizedBox(height: AppSpacing.lg),
                    _FeatureRow(
                        icon: Icons.collections_rounded,
                        label: 'Unlimited Image to PDF'),
                    _FeatureRow(
                        icon: Icons.high_quality_rounded,
                        label: 'High-Quality PDF Export'),
                    _FeatureRow(
                        icon: Icons.layers_rounded, label: 'Batch Scanning'),
                    _FeatureRow(
                        icon: Icons.block_rounded, label: 'No Watermark'),
                  ],
                ),
              ),
            ),
            _PlanSheet(
              plan: _plan,
              onPlan: (p) => setState(() => _plan = p),
              onStart: _finishToHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onRestore});
  final VoidCallback onClose;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          Material(
            color: context.colors.surfaceContainerHighest,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded,
                    color: context.colors.onSurfaceVariant),
              ),
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onRestore, child: const Text('Restore')),
        ],
      ),
    );
  }
}

/// Simplified "highlight tools" promo card.
class _HighlightCard extends StatelessWidget {
  const _HighlightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Edit your scanned PDFs on the go — add annotations, signatures, or highlight important text easily.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: BrandColors.secondaryContainer,
            child: Text(
              'Highlight your scanned',
              style: context.text.titleSmall
                  ?.copyWith(color: BrandColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Tool(icon: Icons.brush_rounded, label: 'Highlight', on: true),
              _Tool(icon: Icons.checklist_rounded, label: 'Recorder'),
              _Tool(icon: Icons.note_add_outlined, label: 'Add Pages'),
              _Tool(icon: Icons.text_fields_rounded, label: 'Extract Text'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, this.on = false});
  final IconData icon;
  final String label;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? BrandColors.secondaryContainer : null,
            border: on
                ? null
                : Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
          ),
          child: Icon(icon,
              size: 22,
              color: on ? BrandColors.primary : context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});
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
              color: context.colors.surfaceContainerHighest,
            ),
            child: Icon(icon, size: 22, color: context.colors.onSurface),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: context.text.titleMedium),
        ],
      ),
    );
  }
}

/// The pinned bottom sheet: plan selector + CTA.
class _PlanSheet extends StatelessWidget {
  const _PlanSheet({
    required this.plan,
    required this.onPlan,
    required this.onStart,
  });

  final _Plan plan;
  final ValueChanged<_Plan> onPlan;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  selected: plan == _Plan.monthly,
                  badge: '3 DAYS FREE',
                  title: 'Monthly',
                  price: '₹ 399',
                  onTap: () => onPlan(_Plan.monthly),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PlanCard(
                  selected: plan == _Plan.annual,
                  badge: 'Explorer',
                  title: 'Annual',
                  price: '₹ 1,999',
                  onTap: () => onPlan(_Plan.annual),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded,
                  size: 18, color: context.colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('No Payment Due Now',
                  style: context.text.bodyMedium
                      ?.copyWith(color: context.colors.onSurface)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(label: 'Start 3-Day Free Trial', onPressed: onStart),
          const SizedBox(height: AppSpacing.xs),
          Text(
            plan == _Plan.monthly
                ? '3 days free trial then ₹ 399 per 1 month'
                : 'Billed ₹ 1,999 per year',
            style: context.text.bodySmall
                ?.copyWith(color: context.tokens.textTertiary),
          ),
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
    final primary = context.colors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? primary : context.colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? primary : null,
                    border: selected
                        ? null
                        : Border.all(color: context.colors.outline),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : null,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge,
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text(
              price,
              style: context.text.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
