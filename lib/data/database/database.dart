import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// A scanned document = a logical grouping of one or more pages.
@DataClassName('DocumentRow')
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single page (image on disk). [filePath] points into the app documents dir;
/// blobs are never stored in SQLite — only metadata + paths.
@DataClassName('PageRow')
class Pages extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(Documents, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  IntColumn get pageIndex => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Documents, Pages])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          // Required for the ON DELETE CASCADE on Pages to fire.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // --- Queries -------------------------------------------------------------

  /// Streams all documents (newest first) for the home list.
  Stream<List<DocumentRow>> watchDocuments() {
    return (select(documents)
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
        .watch();
  }

  /// Ordered pages for a single document.
  Future<List<PageRow>> getPages(String documentId) {
    return (select(pages)
          ..where((t) => t.documentId.equals(documentId))
          ..orderBy([(t) => OrderingTerm.asc(t.pageIndex)]))
        .get();
  }

  Future<void> insertDocumentWithPages(
    DocumentsCompanion document,
    List<PagesCompanion> docPages,
  ) {
    return transaction(() async {
      await into(documents).insert(document);
      await batch((b) => b.insertAll(pages, docPages));
    });
  }

  Future<void> renameDocument(String id, String title) {
    return (update(documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Bumps [updatedAt] without changing anything else (e.g. after editing a
  /// page), so the document re-sorts to the top of the list.
  Future<void> touchDocument(String id) {
    return (update(documents)..where((d) => d.id.equals(id))).write(
      DocumentsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deleteDocument(String id) {
    // Pages are removed via ON DELETE CASCADE.
    return (delete(documents)..where((d) => d.id.equals(id))).go();
  }
}

/// Opens the SQLite file lazily inside the app documents directory and runs the
/// heavy work on a background isolate.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'doc_scanner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
