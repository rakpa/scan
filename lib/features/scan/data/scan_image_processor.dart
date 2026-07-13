import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/scan_mode.dart';

/// Crops a captured photo to the detected document quad.
class ScanImageProcessor {
  Future<String> cropToQuad({
    required String sourcePath,
    required DocumentQuad quad,
    required ScanMode mode,
  }) async {
    if (kIsWeb) return sourcePath;

    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return sourcePath;

    final w = decoded.width;
    final h = decoded.height;

    final xs = quad.corners.map((c) => (c.dx * w).round()).toList();
    final ys = quad.corners.map((c) => (c.dy * h).round()).toList();

    final left = xs.reduce((a, b) => a < b ? a : b).clamp(0, w - 1);
    final top = ys.reduce((a, b) => a < b ? a : b).clamp(0, h - 1);
    final right = xs.reduce((a, b) => a > b ? a : b).clamp(left + 1, w);
    final bottom = ys.reduce((a, b) => a > b ? a : b).clamp(top + 1, h);

    var cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );

    // Light enhancement per scan mode.
    cropped = switch (mode) {
      ScanMode.whiteboard => img.adjustColor(cropped, contrast: 1.12, brightness: 1.04),
      ScanMode.receipt => img.grayscale(cropped),
      ScanMode.idCard => img.adjustColor(cropped, contrast: 1.08),
      _ => img.adjustColor(cropped, contrast: 1.05),
    };

    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(outPath).writeAsBytes(img.encodeJpg(cropped, quality: 92));
    return outPath;
  }
}
