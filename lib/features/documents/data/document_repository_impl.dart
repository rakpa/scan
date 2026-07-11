import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/document_storage.dart';
import '../../../data/database/database.dart';
import '../domain/document_repository.dart';
import '../domain/entities.dart';

/// Drift-backed implementation of [DocumentRepository].
///
/// Maps between Drift row classes and domain entities, and coordinates the
/// database with on-disk image storage.
class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl(this._db, this._storage, this._uuid);

  final AppDatabase _db;
  final DocumentStorage _storage;
  final Uuid _uuid;

  @override
  Stream<List<DocumentSummary>> watchDocuments() {
    // Watch documents, then enrich each with its page count + thumbnail.
    // N+1 per emission is acceptable for the MVP list size; revisit with a
    // single aggregate query if libraries grow large.
    return _db.watchDocuments().asyncMap((rows) async {
      final summaries = <DocumentSummary>[];
      for (final row in rows) {
        final pages = await _db.getPages(row.id);
        summaries.add(
          DocumentSummary(
            document: _toEntity(row),
            pageCount: pages.length,
            thumbnailPath: pages.isEmpty ? null : pages.first.filePath,
          ),
        );
      }
      return summaries;
    });
  }

  @override
  Future<List<ScanPage>> getPages(String documentId) async {
    final rows = await _db.getPages(documentId);
    return rows.map(_toPageEntity).toList();
  }

  @override
  Future<ScanDocument> createDocumentFromScans(
    List<String> imagePaths, {
    String? title,
  }) async {
    final now = DateTime.now();
    final docId = _uuid.v4();
    final docTitle = title ?? _defaultTitle(now);

    // Copy each scanned image into permanent storage.
    final pageCompanions = <PagesCompanion>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final storedPath = await _storage.importPage(
        documentId: docId,
        index: i,
        sourcePath: imagePaths[i],
      );
      pageCompanions.add(
        PagesCompanion.insert(
          id: _uuid.v4(),
          documentId: docId,
          filePath: storedPath,
          pageIndex: i,
          createdAt: now,
        ),
      );
    }

    await _db.insertDocumentWithPages(
      DocumentsCompanion.insert(
        id: docId,
        title: docTitle,
        createdAt: now,
        updatedAt: now,
      ),
      pageCompanions,
    );

    return ScanDocument(
      id: docId,
      title: docTitle,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> renameDocument(String id, String title) {
    return _db.renameDocument(id, title);
  }

  @override
  Future<void> touchDocument(String id) => _db.touchDocument(id);

  @override
  Future<void> deleteDocument(String id) async {
    await _db.deleteDocument(id);
    await _storage.deleteDocumentFiles(id);
  }

  // --- Mapping helpers -----------------------------------------------------

  ScanDocument _toEntity(DocumentRow row) => ScanDocument(
        id: row.id,
        title: row.title,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  ScanPage _toPageEntity(PageRow row) => ScanPage(
        id: row.id,
        documentId: row.documentId,
        filePath: row.filePath,
        index: row.pageIndex,
        createdAt: row.createdAt,
      );

  String _defaultTitle(DateTime now) =>
      'Scan ${DateFormat('yyyy-MM-dd HH:mm').format(now)}';
}
