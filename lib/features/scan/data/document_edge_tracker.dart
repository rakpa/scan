import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import '../domain/scan_mode.dart';

/// Simulates live edge detection with smooth corner animation and stability
/// tracking for auto-capture.
class DocumentEdgeTracker {
  DocumentEdgeTracker({required this.onStable});

  static const _cooldown = Duration(milliseconds: 1500);
  static const _leaveFrameConfidence = 0.5;
  static const _leaveFrameTicks = 12;
  static const _significantChangeThreshold = 0.045;
  static const _duplicateFrameThreshold = 0.022;

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

  bool _autoCaptureLocked = false;
  DateTime? _lockCooldownUntil;
  DocumentQuad? _capturedQuadSnapshot;
  DocumentQuad? _lastAutoCaptureQuad;
  DateTime? _lastAutoCaptureAt;
  var _lowConfidenceTicks = 0;
  var _nextPageRequested = false;
  var _documentLeftFrame = false;

  DocumentQuad get quad => _quad;
  ScanDetectionPhase get phase => _phase;
  double get confidence => _confidence;
  bool get isAutoCaptureLocked => _autoCaptureLocked;
  bool get waitingForNextPage =>
      _autoCaptureLocked && _phase == ScanDetectionPhase.pageCaptured;

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
    _clearAutoCaptureLock();
  }

  void setAutoCapture(bool enabled) {
    _autoCaptureEnabled = enabled;
    if (!enabled) _stability = 0;
  }

  /// Locks auto-capture after a page is saved so the same frame is not shot again.
  void lockAfterCapture(DocumentQuad capturedAt) {
    _capturing = false;
    _stability = 0;
    _autoCaptureLocked = true;
    _lockCooldownUntil = DateTime.now().add(_cooldown);
    _capturedQuadSnapshot = capturedAt;
    _lastAutoCaptureQuad = capturedAt;
    _lastAutoCaptureAt = DateTime.now();
    _nextPageRequested = false;
    _documentLeftFrame = false;
    _lowConfidenceTicks = 0;
    _phase = ScanDetectionPhase.pageCaptured;
  }

  /// User tapped "Next page" — allow auto-capture once cooldown + conditions pass.
  void prepareNextPage() {
    _nextPageRequested = true;
    _tryUnlockAutoCapture();
  }

  void resetAfterCapture() {
    lockAfterCapture(_quad);
  }

  void _clearAutoCaptureLock() {
    _autoCaptureLocked = false;
    _lockCooldownUntil = null;
    _capturedQuadSnapshot = null;
    _nextPageRequested = false;
    _documentLeftFrame = false;
    _lowConfidenceTicks = 0;
  }

  void _unlockAutoCapture() {
    _clearAutoCaptureLock();
    _stability = 0;
    _phase = ScanDetectionPhase.looking;
    _confidence = 0.2;
  }

  bool _cooldownElapsed() {
    final until = _lockCooldownUntil;
    return until == null || !DateTime.now().isBefore(until);
  }

  bool _isDuplicateFrame(DocumentQuad current) {
    final reference = _lastAutoCaptureQuad;
    final capturedAt = _lastAutoCaptureAt;
    if (reference == null || capturedAt == null) return false;

    final elapsed = DateTime.now().difference(capturedAt);
    if (elapsed > const Duration(seconds: 8)) return false;

    return _averageCornerDistance(current, reference) < _duplicateFrameThreshold;
  }

  bool _isSignificantlyDifferentFromSnapshot() {
    final snapshot = _capturedQuadSnapshot;
    if (snapshot == null) return false;
    return _averageCornerDistance(_quad, snapshot) >= _significantChangeThreshold;
  }

  void _trackDocumentPresence() {
    if (_confidence < _leaveFrameConfidence) {
      _lowConfidenceTicks++;
      if (_lowConfidenceTicks >= _leaveFrameTicks) {
        _documentLeftFrame = true;
      }
    } else {
      _lowConfidenceTicks = 0;
    }
  }

  void _tryUnlockAutoCapture() {
    if (!_autoCaptureLocked || !_cooldownElapsed()) return;

    final canUnlock = _nextPageRequested ||
        _documentLeftFrame ||
        _isSignificantlyDifferentFromSnapshot();

    if (canUnlock) {
      _unlockAutoCapture();
    }
  }

  void _tick() {
    if (_capturing) return;

    _updateQuadAndConfidence();

    if (_autoCaptureLocked) {
      _trackDocumentPresence();
      _tryUnlockAutoCapture();
      if (_autoCaptureLocked) {
        _phase = ScanDetectionPhase.pageCaptured;
      }
      return;
    }

    if (_confidence < 0.55) {
      _phase = ScanDetectionPhase.looking;
      _stability = 0;
    } else if (_confidence < 0.82) {
      _phase = ScanDetectionPhase.holdSteady;
      _stability = 0;
    } else {
      _phase = ScanDetectionPhase.holdSteady;
      _stability += 0.05;
      if (_autoCaptureEnabled &&
          _stability >= 1.0 &&
          !_isDuplicateFrame(_quad)) {
        _capturing = true;
        _phase = ScanDetectionPhase.capturing;
        onStable();
      }
    }
  }

  void _updateQuadAndConfidence() {
    const jitter = 0.004;
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
