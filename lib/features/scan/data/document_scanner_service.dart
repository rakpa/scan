import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around the native document scanner plugin.
///
/// On Android this launches the ML Kit Document Scanner (auto edge detection,
/// corner adjustment, multi-page); on iOS it uses VisionKit. Returns the file
/// paths of the cropped page images, or `null` if the user cancelled.
class DocumentScannerService {
  /// Opens the scanner UI.
  ///
  /// [maxPages] caps a single scanning session. Gallery import is allowed so
  /// users can build documents from existing photos too.
  Future<List<String>?> scan({int maxPages = 24}) async {
    if (!kIsWeb) {
      final granted = await _ensureCameraPermission();
      if (!granted) {
        throw StateError(
          'Camera permission is required to scan documents. '
          'Enable it in Settings and try again.',
        );
      }
    }

    final images = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: true,
    );
    return images;
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    status = await Permission.camera.request();
    return status.isGranted;
  }
}
