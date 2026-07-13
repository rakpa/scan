import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../domain/scan_mode.dart';
import 'document_quad_detector.dart';

/// Result of analyzing a single camera frame for a document boundary.
class FrameDetectionResult {
  const FrameDetectionResult({
    required this.quad,
    required this.confidence,
  });

  /// Detected document corners in normalized preview (display) coordinates,
  /// or null when no document was found in this frame.
  final DocumentQuad? quad;
  final double confidence;
}

/// Detects a document quad from live camera YUV frames using the pure-Dart
/// [DocumentQuadDetector] (no ML dependency — works on device + simulator).
class CameraFrameAnalyzer {
  CameraFrameAnalyzer();

  static const _minInterval = Duration(milliseconds: 100);
  static const _analysisWidth = 160;

  final _detector = const DocumentQuadDetector();
  DateTime? _lastProcessed;

  /// Returns null when throttled — callers should keep the previous quad.
  FrameDetectionResult? analyzeThrottled(
    CameraImage image,
    ScanMode mode,
    CameraDescription camera,
  ) {
    final now = DateTime.now();
    if (_lastProcessed != null &&
        now.difference(_lastProcessed!) < _minInterval) {
      return null;
    }
    _lastProcessed = now;
    return analyze(image, mode, camera);
  }

  @visibleForTesting
  FrameDetectionResult analyze(
    CameraImage image,
    ScanMode mode,
    CameraDescription camera,
  ) {
    final grid = _luminanceGrid(image);
    if (grid == null) {
      return const FrameDetectionResult(quad: null, confidence: 0);
    }

    final detection = _detector.detect(grid.bytes, grid.width, grid.height);
    if (detection == null) {
      return const FrameDetectionResult(quad: null, confidence: 0);
    }

    final quad = _toPreviewQuad(detection.corners, camera.sensorOrientation);
    return FrameDetectionResult(quad: quad, confidence: detection.confidence);
  }

  /// Rotates normalized buffer-space corners into upright display space.
  ///
  /// Camera buffers arrive in sensor orientation; the preview rotates them by
  /// [sensorOrientation] degrees clockwise before display, so detected points
  /// must be rotated the same way.
  DocumentQuad _toPreviewQuad(List<Offset> bufferCorners, int sensorOrientation) {
    Offset rotate(Offset p) => switch (sensorOrientation % 360) {
          90 => Offset(1 - p.dy, p.dx),
          180 => Offset(1 - p.dx, 1 - p.dy),
          270 => Offset(p.dy, 1 - p.dx),
          _ => p,
        };

    final rotated = DocumentQuadDetector.orderCorners(
      bufferCorners.map(rotate).toList(growable: false),
    );
    return DocumentQuad(
      topLeft: rotated[0],
      topRight: rotated[1],
      bottomRight: rotated[2],
      bottomLeft: rotated[3],
    );
  }

  _LumGrid? _luminanceGrid(CameraImage image) {
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first; // Y (luminance) on Android and iOS.
    final srcW = image.width;
    final srcH = image.height;
    if (srcW < 16 || srcH < 16) return null;

    const targetW = _analysisWidth;
    final targetH = (targetW * srcH / srcW).round().clamp(48, 220);

    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;
    final pixelStride = plane.bytesPerPixel ?? 1;
    final grid = Uint8List(targetW * targetH);

    for (var y = 0; y < targetH; y++) {
      final srcY = (y * srcH / targetH).floor().clamp(0, srcH - 1);
      final rowBase = srcY * rowStride;
      final dstBase = y * targetW;
      for (var x = 0; x < targetW; x++) {
        final srcX = (x * srcW / targetW).floor().clamp(0, srcW - 1);
        final index = rowBase + srcX * pixelStride;
        if (index < bytes.length) {
          grid[dstBase + x] = bytes[index];
        }
      }
    }
    return _LumGrid(bytes: grid, width: targetW, height: targetH);
  }
}

class _LumGrid {
  const _LumGrid({required this.bytes, required this.width, required this.height});

  final Uint8List bytes;
  final int width;
  final int height;
}
