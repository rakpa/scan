import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../shared/widgets/stitch/stitch_frame.dart';
import '../../onboarding/data/onboarding_store.dart';
import '../../export/presentation/export_controller.dart';
import '../../scan/presentation/scan_controller.dart';
import '../domain/entities.dart';
import 'documents_providers.dart';

/// Document detail — Stitch Document Export PNG + live scan preview overlay.
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
    final premium = ref.watch(onboardingStoreProvider).maybeWhen(
          data: (store) => store.premiumUnlocked,
          orElse: () => false,
        );

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
      backgroundColor: const Color(0xFFF9F9FB),
      body: pagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (pages) {
          final page = pages.isEmpty
              ? null
              : pages[_pageIndex.clamp(0, pages.length - 1)];

          Widget? previewOverlay;
          if (page != null) {
            final file = File(page.filePath);
            if (file.existsSync()) {
              previewOverlay = LayoutBuilder(
                builder: (context, c) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: c.maxHeight * 0.12,
                        bottom: c.maxHeight * 0.22,
                        left: c.maxWidth * 0.08,
                        right: c.maxWidth * 0.08,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file, fit: BoxFit.contain),
                      ),
                    ),
                  );
                },
              );
            }
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              StitchFrame(
                asset: StitchAssets.documentExportFor(premium: premium),
                backgroundColor: const Color(0xFFF9F9FB),
                overlay: previewOverlay,
                hotspots: [
                  StitchHotspot(
                    left: 0.02,
                    top: 0.04,
                    width: 0.12,
                    height: 0.07,
                    semanticLabel: 'Back',
                    onTap: () => context.pop(),
                  ),
                  StitchHotspot(
                    left: 0.86,
                    top: 0.04,
                    width: 0.12,
                    height: 0.07,
                    semanticLabel: 'Rename',
                    onTap: document == null
                        ? () {}
                        : () => _rename(context, ref, document),
                  ),
                  StitchHotspot(
                    left: 0.02,
                    top: 0.88,
                    width: 0.18,
                    height: 0.1,
                    semanticLabel: 'Add page',
                    onTap: scanState.isLoading ? () {} : () => _addPage(ref),
                  ),
                  if (page != null)
                    StitchHotspot(
                      left: 0.22,
                      top: 0.88,
                      width: 0.18,
                      height: 0.1,
                      semanticLabel: 'Enhance',
                      onTap: () => _enhance(context, page, pages.length),
                    ),
                  StitchHotspot(
                    left: 0.32,
                    top: 0.86,
                    width: 0.36,
                    height: 0.12,
                    semanticLabel: 'Export PDF',
                    onTap: exportState.isLoading
                        ? () {}
                        : () => _export(context, ref, document),
                  ),
                  StitchHotspot(
                    left: 0.72,
                    top: 0.88,
                    width: 0.18,
                    height: 0.1,
                    semanticLabel: 'Share',
                    onTap: exportState.isLoading
                        ? () {}
                        : () => _export(context, ref, document),
                  ),
                ],
              ),
              if (scanState.isLoading)
                StitchFrame(
                  asset: StitchAssets.perspectiveCrop,
                  backgroundColor: Colors.black87,
                ),
            ],
          );
        },
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

  void _export(BuildContext context, WidgetRef ref, ScanDocument? document) {
    if (document == null) return;
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
}
