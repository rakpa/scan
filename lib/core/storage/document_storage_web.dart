/// Web preview stub — page files are not persisted on disk.
class DocumentStorage {
  Future<String> importPage({
    required String documentId,
    required int index,
    required String sourcePath,
  }) async {
    return sourcePath;
  }

  Future<void> deleteDocumentFiles(String documentId) async {}
}
