import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../enhance/presentation/enhance_screen.dart';
import '../../export/presentation/export_controller.dart';
import '../domain/entities.dart';
import 'documents_providers.dart';

/// Detail screen for a single document: shows its pages and offers rename,
/// delete, and export-to-PDF actions.
class DocumentDetailScreen extends ConsumerWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(documentPagesProvider(documentId));
    final summariesAsync = ref.watch(documentListProvider);
    final exportState = ref.watch(exportControllerProvider);

    // The document metadata comes from the same stream the list uses.
    final document = summariesAsync.maybeWhen(
      data: (summaries) {
        for (final summary in summaries) {
          if (summary.document.id == documentId) return summary.document;
        }
        return null;
      },
      orElse: () => null,
    );

    ref.listen(exportControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(document?.title ?? 'Document'),
        actions: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            onPressed: document == null
                ? null
                : () => _rename(context, ref, document),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: document == null
                ? null
                : () => _delete(context, ref, document),
          ),
        ],
      ),
      body: pagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
        data: (pages) {
          if (pages.isEmpty) {
            return const Center(child: Text('This document has no pages.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _PageTile(
              page: pages[index],
              pageNumber: index + 1,
              documentId: documentId,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (document == null || exportState.isLoading)
            ? null
            : () => ref
                .read(exportControllerProvider.notifier)
                .exportAndShare(document),
        icon: exportState.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Export PDF'),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ScanDocument document,
  ) async {
    final controller = TextEditingController(text: document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      await ref
          .read(documentRepositoryProvider)
          .renameDocument(document.id, newTitle);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ScanDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${document.title}" and its pages will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(documentRepositoryProvider).deleteDocument(document.id);
      if (context.mounted) context.pop();
    }
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({
    required this.page,
    required this.pageNumber,
    required this.documentId,
  });

  final ScanPage page;
  final int pageNumber;
  final String documentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(page.filePath);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (file.existsSync())
            Image.file(file, fit: BoxFit.contain, cacheWidth: 1080)
          else
            Container(
              height: 200,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: Text('Image missing')),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            child: Row(
              children: [
                Text('Page $pageNumber', style: theme.textTheme.labelLarge),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Enhance'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(
                      builder: (_) => EnhanceScreen(
                        page: page,
                        documentId: documentId,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
