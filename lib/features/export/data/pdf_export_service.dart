import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../documents/domain/entities.dart';

/// Builds a multi-page PDF from a document's pages.
///
/// Each page image is laid out centred on an A4 portrait page, scaled to fit
/// while preserving aspect ratio. Page size/quality options arrive in v1.
class PdfExportService {
  /// Generates the PDF and writes it to a temporary file, returning that file.
  /// The temp dir is used because the output is meant for immediate sharing.
  Future<File> buildPdf({
    required ScanDocument document,
    required List<ScanPage> pages,
  }) async {
    final pdf = pw.Document(title: document.title);

    for (final page in pages) {
      final bytes = await File(page.filePath).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (context) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${_safeFileName(document.title)}.pdf'));
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Strips characters that are unsafe in file names across platforms.
  String _safeFileName(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'document' : cleaned;
  }
}
