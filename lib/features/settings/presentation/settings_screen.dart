import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_version_footer.dart';
import '../../home/presentation/home_design_tokens.dart';
import '../../onboarding/data/onboarding_store.dart';
import 'settings_providers.dart';

/// Native settings — every row here does something real (no mock content).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// True when shown inside the home shell tab (no back button).
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final autoCapture = ref.watch(autoCaptureDefaultProvider);
    final onboarding = ref.watch(onboardingStoreProvider);
    final premium = onboarding.maybeWhen(
      data: (store) => store.premiumUnlocked,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: HomeDesign.canvasOf(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                if (!embedded)
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Padding(
                  padding: EdgeInsets.only(left: embedded ? 8 : 0),
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: HomeDesign.onSurfaceOf(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _PremiumCard(
              premium: premium,
              onTap: premium ? null : () => context.push('/paywall'),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Scanning'),
            _SettingsCard(
              children: [
                SwitchListTile(
                  value: autoCapture,
                  onChanged: (v) =>
                      ref.read(autoCaptureDefaultProvider.notifier).set(v),
                  secondary: const Icon(Icons.center_focus_strong_outlined),
                  title: const Text('Auto-capture'),
                  subtitle: const Text(
                    'Capture automatically when a document is steady',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Appearance'),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theme'),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (selection) => ref
                            .read(themeModeProvider.notifier)
                            .set(selection.first),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionLabel('About'),
            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open-source licenses'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Scanella',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const AppVersionFooter(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: HomeDesign.mutedOf(context),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HomeDesign.surfaceOf(context),
        borderRadius: BorderRadius.circular(HomeDesign.radiusMd),
        boxShadow: HomeDesign.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.premium, this.onTap});

  final bool premium;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeDesign.radiusLg),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [HomeDesign.primary, HomeDesign.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(HomeDesign.radiusLg),
            boxShadow: HomeDesign.fabShadow,
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premium ? 'Premium active' : 'Go Premium',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      premium
                          ? 'Thanks for supporting Scanella'
                          : 'Unlimited scans, filters and PDF export',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!premium)
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
