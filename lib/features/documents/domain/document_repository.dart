import 'entities.dart';

/// Repository contract for documents. The presentation layer depends only on
/// this interface, never on Drift.
abstract interface class DocumentRepository {
  /// Reactive stream of document summaries for the home list.
  Stream<List<DocumentSummary>> watchDocuments();

  /// Ordered pages for a document.
  Future<List<ScanPage>> getPages(String documentId);

  /// Persists a freshly scanned set of images as a new document.
  ///
  /// [imagePaths] are temporary paths returned by the scanner; they are copied
  /// into permanent storage. Returns the created document.
  Future<ScanDocument> createDocumentFromScans(
    List<String> imagePaths, {
    String? title,
  });

  /// Appends scanned images as new pages on an existing document.
  Future<void> appendPagesToDocument(
    String documentId,
    List<String> imagePaths,
  );

  Future<void> renameDocument(String id, String title);

  /// Marks the document as updated (used after a page is edited/enhanced).
  Future<void> touchDocument(String id);

  Future<void> deleteDocument(String id);
}
