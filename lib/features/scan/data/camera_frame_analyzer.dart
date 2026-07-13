import 'dart:math' as math;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../domain/scan_mode.dart';

/// Result of analyzing a single camera frame for a document boundary.
class FrameDetectionResult {
  const FrameDetectionResult({
    required this.quad,
    required this.confidence,
  });

  final DocumentQuad quad;
  final double confidence;
}

/// Detects a document rectangle from live camera YUV frames using contrast
/// against the border background (no ML dependency — works on device + simulator).
class CameraFrameAnalyzer {
  CameraFrameAnalyzer();

  static const _minInterval = Duration(milliseconds: 100);
  static const _analysisWidth = 120;

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
    final fallback = DocumentQuad.forMode(mode);
    final grid = _luminanceGrid(image);
    if (grid == null) {
      return FrameDetectionResult(quad: fallback, confidence: 0.15);
    }

    final h = grid.length;
    final w = grid.first.length;
    final bg = _borderLuminance(grid);
    final threshold = 18 + bg * 0.08;

    var minX = w;
    var minY = h;
    var maxX = 0;
    var maxY = 0;
    var hits = 0;

    final marginX = (w * 0.08).round();
    final marginY = (h * 0.08).round();

    for (var y = marginY; y < h - marginY; y++) {
      for (var x = marginX; x < w - marginX; x++) {
        if ((grid[y][x] - bg).abs() > threshold) {
          hits++;
          minX = math.min(minX, x);
          minY = math.min(minY, y);
          maxX = math.max(maxX, x);
          maxY = math.max(maxY, y);
        }
      }
    }

    final frameArea = (w - 2 * marginX) * (h - 2 * marginY);
    final boxArea = (maxX - minX) * (maxY - minY);
    if (hits < 40 || boxArea < frameArea * 0.08 || maxX <= minX || maxY <= minY) {
      return FrameDetectionResult(quad: fallback, confidence: 0.2);
    }

    final coverage = boxArea / frameArea;
    final confidence = (0.35 + coverage * 1.4).clamp(0.0, 0.98);

    final quad = _mapToPreviewQuad(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      gridW: w,
      gridH: h,
      image: image,
      camera: camera,
      fallback: fallback,
      confidence: confidence,
    );

    return FrameDetectionResult(quad: quad, confidence: confidence);
  }

  List<List<int>>? _luminanceGrid(CameraImage image) {
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    final srcW = image.width;
    final srcH = image.height;
    if (srcW < 8 || srcH < 8) return null;

    final targetH = (_analysisWidth * srcH / srcW).round().clamp(32, 160);
    final targetW = _analysisWidth;

    final bytes = plane.bytes;
    final rowStride = plane.bytesPerRow;
    final grid = List.generate(
      targetH,
      (_) => List<int>.filled(targetW, 0),
    );

    for (var y = 0; y < targetH; y++) {
      final srcY = (y * srcH / targetH).floor().clamp(0, srcH - 1);
      for (var x = 0; x < targetW; x++) {
        final srcX = (x * srcW / targetW).floor().clamp(0, srcW - 1);
        final index = srcY * rowStride + srcX;
        if (index < bytes.length) {
          grid[y][x] = bytes[index];
        }
      }
    }
    return grid;
  }

  double _borderLuminance(List<List<int>> grid) {
    final h = grid.length;
    final w = grid.first.length;
    var sum = 0.0;
    var count = 0;

    void sample(int x, int y) {
      sum += grid[y][x];
      count++;
    }

    for (var x = 0; x < w; x++) {
      sample(x, 0);
      sample(x, h - 1);
    }
    for (var y = 1; y < h - 1; y++) {
      sample(0, y);
      sample(w - 1, y);
    }

    return count == 0 ? 128 : sum / count;
  }

  DocumentQuad _mapToPreviewQuad({
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
    required int gridW,
    required int gridH,
    required CameraImage image,
    required CameraDescription camera,
    required DocumentQuad fallback,
    required double confidence,
  }) {
    double nx(num x) => (x / gridW).clamp(0.02, 0.98);
    double ny(num y) => (y / gridH).clamp(0.02, 0.98);

    // Sensor buffer is often landscape while preview is portrait.
    final rotated = image.width > image.height &&
        camera.sensorOrientation % 180 == 90;

    DocumentQuad detected;
    if (rotated) {
      detected = DocumentQuad(
        topLeft: Offset(nx(minY), ny(minX)),
        topRight: Offset(nx(minY), ny(maxX)),
        bottomRight: Offset(nx(maxY), ny(maxX)),
        bottomLeft: Offset(nx(maxY), ny(minX)),
      );
    } else {
      detected = DocumentQuad(
        topLeft: Offset(nx(minX), ny(minY)),
        topRight: Offset(nx(maxX), ny(minY)),
        bottomRight: Offset(nx(maxX), ny(maxY)),
        bottomLeft: Offset(nx(minX), ny(maxY)),
      );
    }

    final t = (0.25 + confidence * 0.55).clamp(0.25, 0.85);
    return fallback.lerp(detected, t);
  }
}
