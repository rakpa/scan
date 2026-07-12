import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';
import '../../shell/presentation/main_shell.dart';
import '../domain/entities.dart';
import 'documents_providers.dart';

/// Dashboard "Folders" tab — all documents in Stitch grid layout.
class DocumentListTab extends ConsumerStatefulWidget {
  const DocumentListTab({super.key, required this.onScan, this.scanBusy = false});

  final VoidCallback onScan;
  final bool scanBusy;

  @override
  ConsumerState<DocumentListTab> createState() => _DocumentListTabState();
}

class _DocumentListTabState extends ConsumerState<DocumentListTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentListProvider);

    return Column(
      children: [
        StitchDashboardHeader(
          trailingIcon: Icons.sort_rounded,
          onTrailing: () {},
        ),
        Expanded(
          child: docsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (docs) {
              final filtered = docs.where((d) {
                if (_query.isEmpty) return true;
                return d.document.title
                    .toLowerCase()
                    .contains(_query.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return const _EmptyLibrary();
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  100,
                ),
                children: [
                  StitchSearchBar(
                    hint: 'Search folders...',
                    onChanged: (q) => setState(() => _query = q),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'All Documents (${filtered.length})',
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _DocCard(summary: filtered[i]),
                  ),
                ],
              );
            },
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
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 48, color: context.colors.primary),
            const SizedBox(height: 16),
            Text('No documents yet', style: context.text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap the camera button to scan your first document.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone library route — opens shell on Folders tab.
class DocumentListScreen extends StatelessWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell(initialTab: 1);
  }
}
