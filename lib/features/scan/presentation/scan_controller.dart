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
class ScanController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial work; idle until [scanAndSave] is invoked.
  }

  /// Launches the scanner and, if the user captured pages, persists them as a
  /// new document. Returns the created document, or `null` if cancelled.
  Future<ScanDocument?> scanAndSave() async {
    state = const AsyncLoading();
    try {
      final paths = await ref.read(documentScannerServiceProvider).scan();
      if (paths == null || paths.isEmpty) {
        // User cancelled — return to idle without an error.
        state = const AsyncData(null);
        return null;
      }
      final document =
          await ref.read(documentRepositoryProvider).createDocumentFromScans(paths);
      state = const AsyncData(null);
      return document;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final scanControllerProvider =
    AutoDisposeAsyncNotifierProvider<ScanController, void>(ScanController.new);
