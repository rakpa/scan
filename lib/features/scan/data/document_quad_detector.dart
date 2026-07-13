import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// A document quad detected on a grayscale grid, with corners in normalized
/// (0–1) grid coordinates ordered TL, TR, BR, BL.
class QuadDetection {
  const QuadDetection({required this.corners, required this.confidence});

  final List<Offset> corners;
  final double confidence;
}

/// Pure-Dart document boundary detector (no ML / OpenCV dependency).
///
/// Works on a small grayscale grid (~150–400 px wide):
///  1. 3×3 box blur to suppress sensor noise.
///  2. Estimate background luminance/spread from the border ring.
///  3. Threshold pixels that contrast with the background into a mask.
///  4. Keep the largest connected component (the document sheet).
///  5. Extract corners as the component's extreme points along the
///     diagonals (max/min of x+y and x−y) — yields a true quad, not an
///     axis-aligned box, so tilted documents are tracked correctly.
///  6. Score confidence from area coverage, convexity, and how well the
///     quad's perimeter sits on strong luminance gradients.
class DocumentQuadDetector {
  const DocumentQuadDetector();

  /// Minimum fraction of the frame a document must cover to count.
  static const _minAreaRatio = 0.06;

  /// Detects the dominant document quad in a grayscale [lum] grid of
  /// [width]×[height]. Returns null when nothing document-like is found.
  QuadDetection? detect(Uint8List lum, int width, int height) {
    if (width < 16 || height < 16 || lum.length < width * height) return null;

    final blurred = _boxBlur3(lum, width, height);
    final (bg, bgSpread) = _borderStats(blurred, width, height);
    final threshold = math.max(14.0, bgSpread * 2.2 + 6);

    // Binary mask of pixels contrasting with the border background.
    final mask = Uint8List(width * height);
    for (var y = 1; y < height - 1; y++) {
      final row = y * width;
      for (var x = 1; x < width - 1; x++) {
        if ((blurred[row + x] - bg).abs() > threshold) {
          mask[row + x] = 1;
        }
      }
    }

    final component = _largestComponent(mask, width, height);
    if (component == null) return null;

    final areaRatio = component.area / (width * height);
    if (areaRatio < _minAreaRatio) return null;

    final corners = _extremeCorners(component, width);
    if (corners == null) return null;

    if (!_isConvex(corners)) return null;

    final quadArea = _polygonArea(corners);
    final quadAreaRatio = quadArea / (width * height);
    if (quadAreaRatio < _minAreaRatio) return null;

    // How much of the component the quad explains — a ragged blob (hand,
    // shadow patch) has a hull much larger than its filled area.
    final solidity = (component.area / math.max(quadArea, 1)).clamp(0.0, 1.0);
    if (solidity < 0.55) return null;

    final edgeSupport = _edgeSupport(blurred, width, height, corners);

    final confidence = (0.30 +
            0.40 * edgeSupport +
            0.20 * solidity +
            0.10 * math.min(quadAreaRatio * 2.5, 1.0))
        .clamp(0.0, 0.97);

    final normalized = corners
        .map((c) => Offset(
              (c.dx / width).clamp(0.0, 1.0),
              (c.dy / height).clamp(0.0, 1.0),
            ))
        .toList(growable: false);

    return QuadDetection(
      corners: orderCorners(normalized),
      confidence: confidence,
    );
  }

  /// Orders 4 points as TL, TR, BR, BL using the sum/diff heuristic.
  static List<Offset> orderCorners(List<Offset> pts) {
    assert(pts.length == 4);
    Offset pick(double Function(Offset) score, bool minimum) {
      var best = pts.first;
      for (final p in pts.skip(1)) {
        final better = minimum ? score(p) < score(best) : score(p) > score(best);
        if (better) best = p;
      }
      return best;
    }

    final tl = pick((p) => p.dx + p.dy, true);
    final br = pick((p) => p.dx + p.dy, false);
    final tr = pick((p) => p.dx - p.dy, false);
    final bl = pick((p) => p.dx - p.dy, true);
    return [tl, tr, br, bl];
  }

  Uint8List _boxBlur3(Uint8List src, int w, int h) {
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      final y0 = math.max(0, y - 1) * w;
      final y1 = y * w;
      final y2 = math.min(h - 1, y + 1) * w;
      for (var x = 0; x < w; x++) {
        final x0 = math.max(0, x - 1);
        final x2 = math.min(w - 1, x + 1);
        final sum = src[y0 + x0] + src[y0 + x] + src[y0 + x2] +
            src[y1 + x0] + src[y1 + x] + src[y1 + x2] +
            src[y2 + x0] + src[y2 + x] + src[y2 + x2];
        out[y1 + x] = sum ~/ 9;
      }
    }
    return out;
  }

  /// Mean and mean-absolute-deviation of the 2px border ring.
  (double, double) _borderStats(Uint8List lum, int w, int h) {
    var sum = 0.0;
    var count = 0;
    void sample(int x, int y) {
      sum += lum[y * w + x];
      count++;
    }

    for (var t = 0; t < 2; t++) {
      for (var x = 0; x < w; x++) {
        sample(x, t);
        sample(x, h - 1 - t);
      }
      for (var y = 2; y < h - 2; y++) {
        sample(t, y);
        sample(w - 1 - t, y);
      }
    }
    final mean = count == 0 ? 128.0 : sum / count;

    var dev = 0.0;
    for (var t = 0; t < 2; t++) {
      for (var x = 0; x < w; x++) {
        dev += (lum[t * w + x] - mean).abs();
        dev += (lum[(h - 1 - t) * w + x] - mean).abs();
      }
      for (var y = 2; y < h - 2; y++) {
        dev += (lum[y * w + t] - mean).abs();
        dev += (lum[y * w + w - 1 - t] - mean).abs();
      }
    }
    return (mean, count == 0 ? 0 : dev / count);
  }

  _Component? _largestComponent(Uint8List mask, int w, int h) {
    final labels = Int32List(w * h); // 0 = unvisited
    var nextLabel = 0;
    _Component? best;
    final stack = <int>[];

    for (var i = 0; i < mask.length; i++) {
      if (mask[i] == 0 || labels[i] != 0) continue;
      nextLabel++;
      var area = 0;
      final pixels = <int>[];
      stack.add(i);
      labels[i] = nextLabel;

      while (stack.isNotEmpty) {
        final p = stack.removeLast();
        area++;
        pixels.add(p);
        final px = p % w;
        final py = p ~/ w;
        // 4-connectivity is enough at grid resolution and keeps this fast.
        if (px > 0) _tryPush(p - 1, mask, labels, nextLabel, stack);
        if (px < w - 1) _tryPush(p + 1, mask, labels, nextLabel, stack);
        if (py > 0) _tryPush(p - w, mask, labels, nextLabel, stack);
        if (py < h - 1) _tryPush(p + w, mask, labels, nextLabel, stack);
      }

      if (best == null || area > best.area) {
        best = _Component(area: area, pixels: pixels);
      }
    }
    return best;
  }

  void _tryPush(
    int index,
    Uint8List mask,
    Int32List labels,
    int label,
    List<int> stack,
  ) {
    if (mask[index] != 0 && labels[index] == 0) {
      labels[index] = label;
      stack.add(index);
    }
  }

  List<Offset>? _extremeCorners(_Component component, int w) {
    if (component.pixels.length < 12) return null;

    var tl = component.pixels.first;
    var tr = tl, br = tl, bl = tl;
    var tlScore = double.infinity, brScore = -double.infinity;
    var trScore = -double.infinity, blScore = double.infinity;

    for (final p in component.pixels) {
      final x = (p % w).toDouble();
      final y = (p ~/ w).toDouble();
      final sum = x + y;
      final diff = x - y;
      if (sum < tlScore) {
        tlScore = sum;
        tl = p;
      }
      if (sum > brScore) {
        brScore = sum;
        br = p;
      }
      if (diff > trScore) {
        trScore = diff;
        tr = p;
      }
      if (diff < blScore) {
        blScore = diff;
        bl = p;
      }
    }

    Offset toOffset(int p) => Offset((p % w).toDouble(), (p ~/ w).toDouble());
    final corners = [toOffset(tl), toOffset(tr), toOffset(br), toOffset(bl)];

    // Degenerate quads (all corners bunched together) are noise.
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      if ((a - b).distance < 4) return null;
    }
    return corners;
  }

  bool _isConvex(List<Offset> quad) {
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

    var sign = 0;
    for (var i = 0; i < 4; i++) {
      final c = cross(quad[i], quad[(i + 1) % 4], quad[(i + 2) % 4]);
      if (c.abs() < 1e-6) continue;
      final s = c > 0 ? 1 : -1;
      if (sign == 0) {
        sign = s;
      } else if (s != sign) {
        return false;
      }
    }
    return sign != 0;
  }

  double _polygonArea(List<Offset> quad) {
    var area = 0.0;
    for (var i = 0; i < quad.length; i++) {
      final a = quad[i];
      final b = quad[(i + 1) % quad.length];
      area += a.dx * b.dy - b.dx * a.dy;
    }
    return area.abs() / 2;
  }

  /// Fraction of samples along the quad perimeter that sit on a strong
  /// luminance gradient (a real paper edge).
  double _edgeSupport(
    Uint8List lum,
    int w,
    int h,
    List<Offset> corners,
  ) {
    var supported = 0;
    var total = 0;

    double lumAt(double x, double y) {
      final xi = x.round().clamp(0, w - 1);
      final yi = y.round().clamp(0, h - 1);
      return lum[yi * w + xi].toDouble();
    }

    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      final edge = b - a;
      final len = edge.distance;
      if (len < 1) continue;
      // Unit normal to the edge — we compare luminance on both sides.
      final normal = Offset(-edge.dy / len, edge.dx / len);
      final steps = math.max(6, len ~/ 3);
      for (var s = 1; s < steps; s++) {
        final t = s / steps;
        final p = a + edge * t;
        final inside = lumAt(p.dx + normal.dx * 2, p.dy + normal.dy * 2);
        final outside = lumAt(p.dx - normal.dx * 2, p.dy - normal.dy * 2);
        total++;
        if ((inside - outside).abs() > 10) supported++;
      }
    }
    return total == 0 ? 0 : supported / total;
  }
}

class _Component {
  const _Component({required this.area, required this.pixels});

  final int area;
  final List<int> pixels;
}
