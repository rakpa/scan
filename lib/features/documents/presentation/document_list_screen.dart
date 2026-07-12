import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/neu_decorations.dart';
import '../../scan/presentation/scan_controller.dart';
import '../domain/entities.dart';
import 'documents_providers.dart';

/// Home screen: a grid of scanned documents with a "Scan" action.
class DocumentListScreen extends ConsumerWidget {
  const DocumentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);
    final scanState = ref.watch(scanControllerProvider);

    // Surface scan errors as a snackbar.
    ref.listen(scanControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.tokens.canvasBackground,
      appBar: AppBar(
        title: Text('All Documents', style: context.text.titleLarge?.copyWith(
          color: context.colors.primary,
        )),
        backgroundColor: context.colors.surface,
      ),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (documents) {
          if (documents.isEmpty) {
            return const _EmptyState();
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) =>
                _DocumentCard(summary: documents[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanState.isLoading
            ? null
            : () => _onScanPressed(context, ref),
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: scanState.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }

  Future<void> _onScanPressed(BuildContext context, WidgetRef ref) async {
    final document =
        await ref.read(scanControllerProvider.notifier).scanAndSave();
    // Navigate straight into the freshly created document.
    if (document != null && context.mounted) {
      context.push('/document/${document.id}');
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.summary});

  final DocumentSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doc = summary.document;

    return Card(
      child: InkWell(
        onTap: () => context.push('/document/${doc.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Thumbnail(path: summary.thumbnailPath)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${summary.pageCount} page${summary.pageCount == 1 ? '' : 's'} · '
                    '${DateFormat.MMMd().format(doc.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (path == null || !File(path!).existsSync()) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image_not_supported_outlined,
            color: colorScheme.onSurfaceVariant),
      );
    }
    return Image.file(
      File(path!),
      fit: BoxFit.cover,
      // Decode at a reduced resolution for list performance.
      cacheWidth: 400,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_outlined,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('No documents yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap Scan to capture your first document.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
