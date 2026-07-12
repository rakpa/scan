import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';
import '../../shell/presentation/main_shell.dart';
import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';

/// Dashboard "Scans" tab — Stitch Dashboard design.
class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, required this.onScan, this.scanBusy = false});

  final VoidCallback onScan;
  final bool scanBusy;

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  bool _gridView = true;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentListProvider);

    return Column(
      children: [
        StitchDashboardHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              100,
            ),
            children: [
              StitchSearchBar(
                hint: 'Search Scans...',
                onChanged: (q) => setState(() => _query = q),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('Recent Scans', style: context.text.titleMedium),
                  ),
                  StitchViewToggle(
                    gridView: _gridView,
                    onToggle: () => setState(() => _gridView = !_gridView),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              docsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load documents: $e'),
                data: (docs) {
                  final filtered = docs.where((d) {
                    if (_query.isEmpty) return true;
                    return d.document.title
                        .toLowerCase()
                        .contains(_query.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) return const _EmptyRecent();

                  if (_gridView) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) =>
                          _DocCard(summary: filtered[i]),
                    );
                  }

                  return Column(
                    children: [
                      for (final doc in filtered) ...[
                        _DocListTile(summary: doc),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.summary});
  final DocumentSummary summary;

  @override
  Widget build(BuildContext context) {
    final doc = summary.document;
    final thumb = summary.thumbnailPath;

    return StitchScanCard(
      title: doc.title,
      subtitle:
          '${DateFormat.MMMd().format(doc.updatedAt)} · ${summary.pageCount} pg',
      thumbnail: (thumb != null && File(thumb).existsSync())
          ? Image.file(File(thumb), fit: BoxFit.cover, cacheWidth: 400)
          : null,
      onTap: () => context.push('/document/${doc.id}'),
    ).animate().fadeIn(duration: AppDuration.base);
  }
}

class _DocListTile extends StatelessWidget {
  const _DocListTile({required this.summary});
  final DocumentSummary summary;

  @override
  Widget build(BuildContext context) {
    final doc = summary.document;
    final thumb = summary.thumbnailPath;

    return StitchScanCard(
      title: doc.title,
      subtitle:
          '${DateFormat.MMMd().format(doc.updatedAt)} · ${summary.pageCount} pages',
      thumbnail: SizedBox(
        height: 72,
        child: (thumb != null && File(thumb).existsSync())
            ? Image.file(File(thumb), fit: BoxFit.cover)
            : Container(
                color: context.colors.surfaceContainerHighest,
                child: Icon(Icons.description_outlined,
                    color: context.colors.onSurfaceVariant),
              ),
      ),
      onTap: () => context.push('/document/${doc.id}'),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 48, color: context.colors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('No scans yet', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap the camera button to capture your first document.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Legacy export — home route now uses [MainShell].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell(initialTab: 0);
  }
}
