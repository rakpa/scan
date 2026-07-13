import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/scan_mode.dart';
import 'document_quad_detector.dart';

/// Crops a captured photo to the document boundary with true perspective
/// correction (keystone removal), like a native scanner.
///
/// The document quad is re-detected on the captured still itself (higher
/// quality than the live preview estimate); the live [quad] is only a hint.
/// All decoding and pixel work runs on a background isolate via [compute].
class ScanImageProcessor {
  Future<String> cropToQuad({
    required String sourcePath,
    required DocumentQuad quad,
    required ScanMode mode,
    bool applyModeEnhancement = true,
  }) async {
    if (kIsWeb) return sourcePath;

    final dir = await getTemporaryDirectory();
    final outPath = p.join(
      dir.path,
      'scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    return compute(
      _runCropAndRectify,
      _CropArgs(
        sourcePath: sourcePath,
        outPath: outPath,
        modeIndex: mode.index,
        applyModeEnhancement: applyModeEnhancement,
        liveCorners: quad.corners
            .map((c) => [c.dx, c.dy])
            .toList(growable: false),
      ),
    );
  }
}

@immutable
class _CropArgs {
  const _CropArgs({
    required this.sourcePath,
    required this.outPath,
    required this.modeIndex,
    required this.applyModeEnhancement,
    required this.liveCorners,
  });

  final String sourcePath;
  final String outPath;
  final int modeIndex;
  final bool applyModeEnhancement;

  /// TL/TR/BR/BL corners from the live tracker, normalized to preview space.
  final List<List<double>> liveCorners;
}

/// Top-level entry point executed on the background isolate.
Future<String> _runCropAndRectify(_CropArgs args) async {
  final bytes = await File(args.sourcePath).readAsBytes();
  var decoded = img.decodeImage(bytes);
  if (decoded == null) return args.sourcePath;

  decoded = img.bakeOrientation(decoded);

  final corners = _detectStillCorners(decoded) ?? _liveCornersFor(decoded, args);

  var result = corners != null
      ? _warpPerspective(decoded, corners)
      : decoded; // No confident boundary — keep the full frame.

  if (args.applyModeEnhancement) {
    final mode = ScanMode.values[args.modeIndex];
    result = switch (mode) {
      ScanMode.whiteboard =>
        img.adjustColor(result, contrast: 1.12, brightness: 1.04),
      ScanMode.receipt => img.grayscale(result),
      ScanMode.idCard => img.adjustColor(result, contrast: 1.08),
      _ => img.adjustColor(result, contrast: 1.05),
    };
  }

  await File(args.outPath).writeAsBytes(img.encodeJpg(result, quality: 92));
  return args.outPath;
}

/// Runs the shared quad detector on a downscaled grayscale copy of the still.
/// Returns corners in full-resolution pixel coordinates, or null.
List<Offset>? _detectStillCorners(img.Image still) {
  const analysisWidth = 300;
  final scale = still.width / analysisWidth;
  const gridW = analysisWidth;
  final gridH = (still.height / scale).round().clamp(48, 460);

  final small = img.copyResize(
    still,
    width: gridW,
    height: gridH,
    interpolation: img.Interpolation.average,
  );

  final lum = Uint8List(gridW * gridH);
  for (var y = 0; y < gridH; y++) {
    for (var x = 0; x < gridW; x++) {
      lum[y * gridW + x] = img.getLuminance(small.getPixel(x, y)).round();
    }
  }

  final detection = const DocumentQuadDetector().detect(lum, gridW, gridH);
  if (detection == null || detection.confidence < 0.45) return null;

  return detection.corners
      .map((c) => Offset(c.dx * still.width, c.dy * still.height))
      .toList(growable: false);
}

/// Maps the live preview quad onto the still as a fallback hint. Only trusted
/// when it differs meaningfully from the full frame (otherwise cropping adds
/// nothing and risks cutting content).
List<Offset>? _liveCornersFor(img.Image still, _CropArgs args) {
  final corners = args.liveCorners
      .map((c) => Offset(
            (c[0] * still.width).clamp(0.0, still.width.toDouble()),
            (c[1] * still.height).clamp(0.0, still.height.toDouble()),
          ))
      .toList(growable: false);

  final area = _quadArea(corners);
  final frameArea = still.width * still.height;
  final ratio = area / frameArea;
  if (ratio < 0.15 || ratio > 0.95) return null;
  return corners;
}

double _quadArea(List<Offset> quad) {
  var area = 0.0;
  for (var i = 0; i < quad.length; i++) {
    final a = quad[i];
    final b = quad[(i + 1) % quad.length];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  return area.abs() / 2;
}

/// True perspective rectification: maps the source quad (TL/TR/BR/BL) onto an
/// upright rectangle sized from the quad's real edge lengths.
img.Image _warpPerspective(img.Image src, List<Offset> corners) {
  final tl = corners[0], tr = corners[1], br = corners[2], bl = corners[3];

  final topLen = (tr - tl).distance;
  final bottomLen = (br - bl).distance;
  final leftLen = (bl - tl).distance;
  final rightLen = (br - tr).distance;

  var outW = math.max(topLen, bottomLen).round();
  var outH = math.max(leftLen, rightLen).round();
  if (outW < 8 || outH < 8) return src;

  // Cap output size while preserving aspect.
  const maxSide = 2200;
  final longSide = math.max(outW, outH);
  if (longSide > maxSide) {
    final s = maxSide / longSide;
    outW = (outW * s).round();
    outH = (outH * s).round();
  }

  // Homography from destination rectangle to source quad, so each output
  // pixel samples its source location (inverse mapping — no holes).
  final h = _homographyFromRect(
    outW.toDouble(),
    outH.toDouble(),
    tl,
    tr,
    br,
    bl,
  );
  if (h == null) return src;

  final out = img.Image(width: outW, height: outH, numChannels: 3);
  final maxX = src.width - 1.0;
  final maxY = src.height - 1.0;

  for (var y = 0; y < outH; y++) {
    for (var x = 0; x < outW; x++) {
      final denom = h[6] * x + h[7] * y + 1.0;
      final sx = ((h[0] * x + h[1] * y + h[2]) / denom).clamp(0.0, maxX);
      final sy = ((h[3] * x + h[4] * y + h[5]) / denom).clamp(0.0, maxY);
      final pixel = src.getPixelInterpolate(
        sx,
        sy,
        interpolation: img.Interpolation.linear,
      );
      out.setPixelRgb(x, y, pixel.r, pixel.g, pixel.b);
    }
  }
  return out;
}

/// Solves the 8-DOF homography mapping (0,0),(w,0),(w,h),(0,h) to the four
/// source corners. Returns [a,b,c,d,e,f,g,h] or null when degenerate.
List<double>? _homographyFromRect(
  double w,
  double h,
  Offset tl,
  Offset tr,
  Offset br,
  Offset bl,
) {
  final srcPts = [Offset.zero, Offset(w, 0), Offset(w, h), Offset(0, h)];
  final dstPts = [tl, tr, br, bl];

  // Build the standard 8x8 system A*p = b for the projective transform.
  final a = List.generate(8, (_) => List<double>.filled(9, 0));
  for (var i = 0; i < 4; i++) {
    final x = srcPts[i].dx, y = srcPts[i].dy;
    final u = dstPts[i].dx, v = dstPts[i].dy;
    a[i * 2]
      ..[0] = x
      ..[1] = y
      ..[2] = 1
      ..[6] = -u * x
      ..[7] = -u * y
      ..[8] = u;
    a[i * 2 + 1]
      ..[3] = x
      ..[4] = y
      ..[5] = 1
      ..[6] = -v * x
      ..[7] = -v * y
      ..[8] = v;
  }

  // Gaussian elimination with partial pivoting.
  for (var col = 0; col < 8; col++) {
    var pivot = col;
    for (var r = col + 1; r < 8; r++) {
      if (a[r][col].abs() > a[pivot][col].abs()) pivot = r;
    }
    if (a[pivot][col].abs() < 1e-9) return null;
    if (pivot != col) {
      final tmp = a[col];
      a[col] = a[pivot];
      a[pivot] = tmp;
    }
    for (var r = 0; r < 8; r++) {
      if (r == col) continue;
      final factor = a[r][col] / a[col][col];
      if (factor == 0) continue;
      for (var c = col; c < 9; c++) {
        a[r][c] -= factor * a[col][c];
      }
    }
  }

  return List<double>.generate(8, (i) => a[i][8] / a[i][i]);
}
