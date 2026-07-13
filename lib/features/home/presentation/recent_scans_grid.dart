import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/entities.dart';
import 'documents_providers.dart';

/// Live grid of captured scans — replaces Stitch HTML demo placeholders.
class RecentScansGrid extends ConsumerWidget {
  const RecentScansGrid({
    super.key,
    required this.onDocumentTap,
  });

  final ValueChanged<String> onDocumentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListProvider);

    return documents.when(
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Center(
        child: Text(
          'Could not load scans',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
      data: (summaries) {
        if (summaries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No scans yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap the camera button below to scan your first document.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: summaries.length,
          itemBuilder: (context, index) {
            return _ScanCard(
              summary: summaries[index],
              onTap: () => onDocumentTap(summaries[index].document.id),
            );
          },
        );
      },
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.summary, required this.onTap});

  final DocumentSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d').format(summary.document.updatedAt);
    final thumb = summary.thumbnailPath;

    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: const Color(0xFFE8E8EA),
                    child: thumb != null && File(thumb).existsSync()
                        ? Image.file(
                            File(thumb),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(
                              Icons.description_outlined,
                              size: 36,
                              color: Color(0xFF737785),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary.document.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$date · ${summary.pageCount} pg',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF737785),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
