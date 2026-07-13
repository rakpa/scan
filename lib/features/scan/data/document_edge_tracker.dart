import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../domain/scan_mode.dart';

/// Simulates live edge detection with smooth corner animation and stability
/// tracking for auto-capture.
class DocumentEdgeTracker {
  DocumentEdgeTracker({required this.onStable});

  final VoidCallback onStable;

  DocumentQuad _quad = DocumentQuad.forMode(ScanMode.document);
  DocumentQuad _target = DocumentQuad.forMode(ScanMode.document);
  ScanDetectionPhase _phase = ScanDetectionPhase.looking;
  double _confidence = 0;
  double _stability = 0;
  Timer? _timer;
  final _random = math.Random();
  bool _autoCaptureEnabled = true;
  bool _capturing = false;

  DocumentQuad get quad => _quad;
  ScanDetectionPhase get phase => _phase;
  double get confidence => _confidence;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void setMode(ScanMode mode) {
    _target = DocumentQuad.forMode(mode);
    _stability = 0;
    _phase = ScanDetectionPhase.looking;
  }

  void setAutoCapture(bool enabled) {
    _autoCaptureEnabled = enabled;
    if (!enabled) _stability = 0;
  }

  void resetAfterCapture() {
    _capturing = false;
    _stability = 0;
    _phase = ScanDetectionPhase.looking;
    _confidence = 0.2;
  }

  void _tick() {
    if (_capturing) return;

    final jitter = 0.004;
    final noisyTarget = DocumentQuad(
      topLeft: _target.topLeft +
          Offset(
            (_random.nextDouble() - 0.5) * jitter,
            (_random.nextDouble() - 0.5) * jitter,
          ),
      topRight: _target.topRight +
          Offset(
            (_random.nextDouble() - 0.5) * jitter,
            (_random.nextDouble() - 0.5) * jitter,
          ),
      bottomRight: _target.bottomRight +
          Offset(
            (_random.nextDouble() - 0.5) * jitter,
            (_random.nextDouble() - 0.5) * jitter,
          ),
      bottomLeft: _target.bottomLeft +
          Offset(
            (_random.nextDouble() - 0.5) * jitter,
            (_random.nextDouble() - 0.5) * jitter,
          ),
    );

    _quad = _quad.lerp(noisyTarget, 0.18);
    final delta = _averageCornerDistance(_quad, _target);
    _confidence = (1 - (delta / 0.08)).clamp(0.0, 1.0);

    if (_confidence < 0.55) {
      _phase = ScanDetectionPhase.looking;
      _stability = 0;
    } else if (_confidence < 0.82) {
      _phase = ScanDetectionPhase.holdSteady;
      _stability = 0;
    } else {
      _phase = ScanDetectionPhase.holdSteady;
      _stability += 0.05;
      if (_autoCaptureEnabled && _stability >= 1.0) {
        _capturing = true;
        _phase = ScanDetectionPhase.capturing;
        onStable();
      }
    }
  }

  double _averageCornerDistance(DocumentQuad a, DocumentQuad b) {
    final ac = a.corners;
    final bc = b.corners;
    var sum = 0.0;
    for (var i = 0; i < 4; i++) {
      sum += (ac[i] - bc[i]).distance;
    }
    return sum / 4;
  }

  void dispose() => stop();
}
