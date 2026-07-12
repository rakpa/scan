import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/neu_decorations.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';
import '../../export/presentation/export_controller.dart';
import '../../scan/presentation/scan_controller.dart';
import '../domain/entities.dart';
import 'documents_providers.dart';

/// Document detail — Stitch "Document Export" design with scanning integrated.
class DocumentDetailScreen extends ConsumerStatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pagesAsync = ref.watch(documentPagesProvider(widget.documentId));
    final summariesAsync = ref.watch(documentListProvider);
    final exportState = ref.watch(exportControllerProvider);
    final scanState = ref.watch(scanControllerProvider);

    final document = summariesAsync.maybeWhen(
      data: (summaries) {
        for (final s in summaries) {
          if (s.document.id == widget.documentId) return s.document;
        }
        return null;
      },
      orElse: () => null,
    );

    ref.listen(exportControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${next.error}')),
        );
      }
    });

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          StitchTransactionalHeader(
            title: document?.title ?? 'Document',
            subtitle: pagesAsync.maybeWhen(
              data: (p) => '(${p.length} Page${p.length == 1 ? '' : 's'})',
              orElse: () => null,
            ),
            onBack: () => context.pop(),
            actionIcon: Icons.edit_outlined,
            onActionIcon: document != null
                ? () => _rename(context, ref, document)
                : () {},
          ),
          Expanded(
            child: pagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (pages) {
                if (pages.isEmpty) {
                  return const Center(child: Text('No pages in this document.'));
                }
                final page = pages[_pageIndex.clamp(0, pages.length - 1)];
                final file = File(page.filePath);

                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Container(
                          decoration: NeuDecorations.card(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: file.existsSync()
                                ? Image.file(file, fit: BoxFit.contain)
                                : Container(
                                    color: context.colors.surfaceContainerHighest,
                                    child: Icon(Icons.image_not_supported_outlined,
                                        color: context.colors.onSurfaceVariant),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (pages.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pages.length, (i) {
                            final active = i == _pageIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _pageIndex = i),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: active ? 16 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: active
                                      ? context.colors.primary
                                      : context.colors.outlineVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _ExportToolbar(
            exportBusy: exportState.isLoading,
            scanBusy: scanState.isLoading,
            onAddPage: () => _addPage(ref),
            onEnhance: pagesAsync.maybeWhen(
              data: (pages) => pages.isEmpty
                  ? null
                  : () => _enhance(
                        context,
                        pages[_pageIndex.clamp(0, pages.length - 1)],
                        pages.length,
                      ),
              orElse: () => null,
            ),
            onExport: document == null || exportState.isLoading
                ? null
                : () => _export(context, ref, document),
            onShare: document == null || exportState.isLoading
                ? null
                : () => _export(context, ref, document),
            onDelete: document == null
                ? null
                : () => _delete(context, ref, document),
          ),
        ],
      ),
    );
  }

  Future<void> _addPage(WidgetRef ref) async {
    final added = await ref
        .read(scanControllerProvider.notifier)
        .scanAndAppend(widget.documentId);
    if (!added || !mounted) return;
    ref.invalidate(documentPagesProvider(widget.documentId));
    ref.invalidate(documentListProvider);
    final pages =
        await ref.read(documentPagesProvider(widget.documentId).future);
    if (mounted) setState(() => _pageIndex = pages.length - 1);
  }

  void _enhance(BuildContext context, ScanPage page, int total) {
    context.push(
      '/document/${widget.documentId}/page/${page.id}/enhance',
      extra: {
        'page': page,
        'pageNumber': page.index + 1,
        'pageTotal': total,
      },
    );
  }

  void _export(BuildContext context, WidgetRef ref, ScanDocument document) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
    ref
        .read(exportControllerProvider.notifier)
        .exportAndShare(document, sharePositionOrigin: origin);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ScanDocument document,
  ) async {
    final controller = TextEditingController(text: document.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      await ref.read(documentRepositoryProvider).renameDocument(document.id, newTitle);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ScanDocument document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${document.title}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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

/// Bottom toolbar matching Stitch Document Export screen.
class _ExportToolbar extends StatelessWidget {
  const _ExportToolbar({
    required this.exportBusy,
    required this.scanBusy,
    this.onAddPage,
    this.onEnhance,
    this.onExport,
    this.onShare,
    this.onDelete,
  });

  final bool exportBusy;
  final bool scanBusy;
  final VoidCallback? onAddPage;
  final VoidCallback? onEnhance;
  final VoidCallback? onExport;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolBtn(
                icon: Icons.note_add_outlined,
                label: 'Add Page',
                onTap: scanBusy ? null : onAddPage,
                busy: scanBusy,
              ),
              _ToolBtn(
                icon: Icons.auto_fix_high_outlined,
                label: 'Enhance',
                onTap: onEnhance,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FilledButton.icon(
                    onPressed: exportBusy ? null : onExport,
                    icon: exportBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    label: const Text('Export PDF'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              _ToolBtn(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: exportBusy ? null : onShare,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.surface,
                boxShadow: NeuDecorations.flat(),
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(label, style: context.text.labelSmall),
          ],
        ),
      ),
    );
  }
}
