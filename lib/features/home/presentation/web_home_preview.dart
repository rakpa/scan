import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import 'widgets/scan_hero.dart';

/// A web-only stand-in for the home screen.
///
/// The real home depends on the native database (drift/`dart:io`), which can't
/// run in a browser — so this preview shows the home layout and the scan hero
/// without touching the DB, plus a note and a way to replay onboarding.
class WebHomePreview extends StatelessWidget {
  const WebHomePreview({super.key});

  void _note(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xxxl),
          children: [
            Text('Good day', style: context.text.bodyMedium),
            Text('Ready to scan?', style: context.text.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            ScanHero(
              onTap: () => _note(
                  context, 'Scanning runs in the installed app (native).'),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.outlineVariant),
                color: context.colors.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: context.colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Browser preview — scanning, filters, PDF export and the '
                      'document library work in the installed app.',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => context.go('/onboarding'),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Replay onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}
