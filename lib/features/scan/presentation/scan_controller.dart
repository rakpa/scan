import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';
import '../data/document_scanner_service.dart';

final documentScannerServiceProvider = Provider<DocumentScannerService>((ref) {
  return DocumentScannerService();
});

/// Drives the "scan a new document" flow and exposes loading/error state to the
/// UI (e.g. to show a spinner or a snackbar).
class ScanController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial work; idle until [scanAndSave] is invoked.
  }

  /// Persists pre-captured page paths as a new document.
  Future<ScanDocument?> saveFromPaths(
    List<String> paths, {
    String? folderId,
  }) async {
    if (paths.isEmpty) return null;
    state = const AsyncLoading();
    try {
      final document = await ref
          .read(documentRepositoryProvider)
          .createDocumentFromScans(paths, folderId: folderId);
      state = const AsyncData(null);
      return document;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  /// Appends pre-captured page paths to an existing document.
  Future<bool> saveAppendedPages(String documentId, List<String> paths) async {
    if (paths.isEmpty) return false;
    state = const AsyncLoading();
    try {
      await ref
          .read(documentRepositoryProvider)
          .appendPagesToDocument(documentId, paths);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  /// Launches the scanner and, if the user captured pages, persists them as a
  /// new document. Returns the created document, or `null` if cancelled.
  Future<ScanDocument?> scanAndSave({String? folderId}) async {
    state = const AsyncLoading();
    try {
      final paths = await ref.read(documentScannerServiceProvider).scan();
      if (paths == null || paths.isEmpty) {
        // User cancelled — return to idle without an error.
        state = const AsyncData(null);
        return null;
      }
      final document = await ref
          .read(documentRepositoryProvider)
          .createDocumentFromScans(paths, folderId: folderId);
      state = const AsyncData(null);
      return document;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
  /// Launches the scanner and appends captured pages to [documentId].
  Future<bool> scanAndAppend(String documentId) async {
    state = const AsyncLoading();
    try {
      final paths = await ref.read(documentScannerServiceProvider).scan();
      if (paths == null || paths.isEmpty) {
        state = const AsyncData(null);
        return false;
      }
      await ref
          .read(documentRepositoryProvider)
          .appendPagesToDocument(documentId, paths);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final scanControllerProvider =
    AsyncNotifierProvider<ScanController, void>(ScanController.new);
