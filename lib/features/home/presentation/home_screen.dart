import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';
import '../../scan/presentation/scan_controller.dart';
import 'widgets/scan_hero.dart';

/// The premium dashboard home: greeting, the scan hero, quick actions, recent
/// documents, and feature highlights.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanState = ref.watch(scanControllerProvider);
    final docsAsync = ref.watch(documentListProvider);

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    Future<void> scan() async {
      final doc = await ref.read(scanControllerProvider.notifier).scanAndSave();
      if (doc != null && context.mounted) context.push('/document/${doc.id}');
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          children: [
            const _GreetingHeader(),
            const SizedBox(height: AppSpacing.xl),
            ScanHero(onTap: scan, busy: scanState.isLoading)
                .animate()
                .fadeIn(duration: AppDuration.base)
                .moveY(begin: 16, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: AppSpacing.xl),
            _QuickActions(onScan: scan, onImport: scan),
            const SizedBox(height: AppSpacing.xxl),
            _SectionHeader(
              title: 'Recent documents',
              actionLabel: 'See all',
              onAction: () => context.push('/library'),
            ),
            const SizedBox(height: AppSpacing.md),
            _RecentDocuments(docsAsync: docsAsync),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionHeader(title: 'Highlights'),
            const SizedBox(height: AppSpacing.md),
            const _FeatureHighlights(),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: context.text.bodyMedium
                    ?.copyWith(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                'Ready to scan?',
                style: context.text.headlineSmall,
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.folder_open_rounded,
          onTap: () => context.push('/library'),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, color: context.colors.onSurface),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onScan, required this.onImport});
  final VoidCallback onScan;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickAction>[
      _QuickAction(Icons.document_scanner_rounded, 'Scan', onScan),
      _QuickAction(Icons.photo_library_rounded, 'Import', onImport),
      _QuickAction(Icons.badge_rounded, 'ID Card', () => _soon(context)),
      _QuickAction(Icons.qr_code_scanner_rounded, 'QR Code', () => _soon(context)),
    ];
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(child: _QuickActionTile(item)),
          if (item != items.last) const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile(this.action);
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(action.icon, color: context.colors.primary, size: 24),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(action.label, style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleLarge)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _RecentDocuments extends StatelessWidget {
  const _RecentDocuments({required this.docsAsync});
  final AsyncValue<List<DocumentSummary>> docsAsync;

  @override
  Widget build(BuildContext context) {
    return docsAsync.when(
      loading: () => const _RecentSkeleton(),
      error: (e, _) => Text('Could not load documents: $e'),
      data: (docs) {
        if (docs.isEmpty) return const _EmptyRecent();
        final recent = docs.take(8).toList();
        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => _RecentCard(summary: recent[i]),
          ),
        );
      },
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.summary});
  final DocumentSummary summary;

  @override
  Widget build(BuildContext context) {
    final doc = summary.document;
    final thumb = summary.thumbnailPath;
    return SizedBox(
      width: 134,
      child: Material(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/document/${doc.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: (thumb != null && File(thumb).existsSync())
                    ? Image.file(File(thumb), fit: BoxFit.cover, cacheWidth: 280)
                    : Container(
                        color: context.colors.surface,
                        child: Icon(Icons.description_outlined,
                            color: context.colors.onSurfaceVariant),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${summary.pageCount} page${summary.pageCount == 1 ? '' : 's'}',
                      style: context.text.bodySmall
                          ?.copyWith(color: context.tokens.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, _) => Container(
          width: 134,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1200.ms,
              color: context.colors.surface,
            ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              color: context.colors.onSurfaceVariant, size: 32),
          const SizedBox(height: AppSpacing.xs),
          Text('No documents yet', style: context.text.titleSmall),
          const SizedBox(height: 2),
          Text(
            'Your scans will appear here.',
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FeatureHighlights extends StatelessWidget {
  const _FeatureHighlights();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _HighlightCard(
            icon: Icons.auto_fix_high_rounded,
            title: 'Smart enhance',
            body: 'Magic Color & B&W filters',
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _HighlightCard(
            icon: Icons.picture_as_pdf_rounded,
            title: 'Export PDF',
            body: 'Multi-page, share anywhere',
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
        color: context.colors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: context.colors.primary, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: context.text.titleSmall),
          const SizedBox(height: 2),
          Text(
            body,
            style: context.text.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
