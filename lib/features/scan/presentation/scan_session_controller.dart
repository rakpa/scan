import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camera_scan_service.dart';
import '../data/document_edge_tracker.dart';
import '../data/gallery_import_service.dart';
import '../data/scan_image_processor.dart';
import '../domain/scan_mode.dart';

final cameraScanServiceProvider = Provider<CameraScanService>((ref) {
  final service = CameraScanService();
  ref.onDispose(service.dispose);
  return service;
});

final galleryImportServiceProvider = Provider((ref) => GalleryImportService());

final scanImageProcessorProvider = Provider((ref) => ScanImageProcessor());

/// In-memory scan session while the camera screen is open.
class ScanSessionState {
  const ScanSessionState({
    this.mode = ScanMode.document,
    this.capturedPaths = const [],
    this.phase = ScanDetectionPhase.looking,
    this.confidence = 0,
    this.quad,
    this.flashOn = false,
    this.autoCapture = true,
    this.isCapturing = false,
    this.showFlashOverlay = false,
    this.step = ScanStep.capture,
    this.cameraReady = false,
    this.cameraError,
  });

  final ScanMode mode;
  final List<String> capturedPaths;
  final ScanDetectionPhase phase;
  final double confidence;
  final DocumentQuad? quad;
  final bool flashOn;
  final bool autoCapture;
  final bool isCapturing;
  final bool showFlashOverlay;
  final ScanStep step;
  final bool cameraReady;
  final String? cameraError;

  int get pageCount => capturedPaths.length;

  ScanSessionState copyWith({
    ScanMode? mode,
    List<String>? capturedPaths,
    ScanDetectionPhase? phase,
    double? confidence,
    DocumentQuad? quad,
    bool? flashOn,
    bool? autoCapture,
    bool? isCapturing,
    bool? showFlashOverlay,
    ScanStep? step,
    bool? cameraReady,
    String? cameraError,
  }) {
    return ScanSessionState(
      mode: mode ?? this.mode,
      capturedPaths: capturedPaths ?? this.capturedPaths,
      phase: phase ?? this.phase,
      confidence: confidence ?? this.confidence,
      quad: quad ?? this.quad,
      flashOn: flashOn ?? this.flashOn,
      autoCapture: autoCapture ?? this.autoCapture,
      isCapturing: isCapturing ?? this.isCapturing,
      showFlashOverlay: showFlashOverlay ?? this.showFlashOverlay,
      step: step ?? this.step,
      cameraReady: cameraReady ?? this.cameraReady,
      cameraError: cameraError,
    );
  }
}

enum ScanStep { capture, review }

class ScanSessionNotifier extends StateNotifier<ScanSessionState> {
  ScanSessionNotifier(this._ref) : super(const ScanSessionState());

  final Ref _ref;
  DocumentEdgeTracker? _tracker;
  CameraController? _cameraController;

  CameraController? get cameraController => _cameraController;

  Future<void> initializeCamera() async {
    try {
      final service = _ref.read(cameraScanServiceProvider);
      await service.initialize();
      _cameraController = service.controller;
      _startTracker();
      state = state.copyWith(cameraReady: true, cameraError: null);
    } catch (e) {
      state = state.copyWith(cameraReady: false, cameraError: e.toString());
    }
  }

  void _startTracker() {
    _tracker?.dispose();
    _tracker = DocumentEdgeTracker(onStable: _onAutoCapture);
    _tracker!
      ..setMode(state.mode)
      ..setAutoCapture(state.autoCapture)
      ..start();
  }

  void bindCamera(CameraController controller) {
    _cameraController = controller;
  }

  void updateDetection() {
    final tracker = _tracker;
    if (tracker == null) return;
    state = state.copyWith(
      quad: tracker.quad,
      phase: tracker.phase,
      confidence: tracker.confidence,
    );
  }

  void setMode(ScanMode mode) {
    _tracker?.setMode(mode);
    state = state.copyWith(mode: mode);
  }

  void setAutoCapture(bool enabled) {
    _tracker?.setAutoCapture(enabled);
    state = state.copyWith(autoCapture: enabled);
  }

  Future<void> toggleFlash() async {
    final on = await _ref.read(cameraScanServiceProvider).toggleFlash();
    state = state.copyWith(flashOn: on);
  }

  Future<void> capture({bool manual = true}) async {
    if (state.isCapturing) return;
    state = state.copyWith(
      isCapturing: true,
      phase: ScanDetectionPhase.capturing,
      showFlashOverlay: true,
    );

    try {
      final rawPath = await _ref.read(cameraScanServiceProvider).capture();
      final quad = _tracker?.quad ?? DocumentQuad.forMode(state.mode);
      final processed = await _ref.read(scanImageProcessorProvider).cropToQuad(
            sourcePath: rawPath,
            quad: quad,
            mode: state.mode,
          );

      state = state.copyWith(
        capturedPaths: [...state.capturedPaths, processed],
        isCapturing: false,
        showFlashOverlay: false,
      );
      _tracker?.resetAfterCapture();
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        showFlashOverlay: false,
        phase: ScanDetectionPhase.looking,
      );
      rethrow;
    }
  }

  Future<void> _onAutoCapture() async {
    if (!state.autoCapture || state.isCapturing) return;
    await capture(manual: false);
  }

  Future<void> importFromGallery() async {
    final paths = await _ref.read(galleryImportServiceProvider).pickPhotos();
    if (paths.isEmpty) return;
    state = state.copyWith(
      capturedPaths: [...state.capturedPaths, ...paths],
    );
  }

  void goToReview() {
    if (state.capturedPaths.isEmpty) return;
    state = state.copyWith(step: ScanStep.review);
    _tracker?.stop();
  }

  void backToCapture() {
    state = state.copyWith(step: ScanStep.capture);
    _tracker?.start();
  }

  void removePage(int index) {
    final paths = [...state.capturedPaths]..removeAt(index);
    state = state.copyWith(capturedPaths: paths);
  }

  @override
  void dispose() {
    _tracker?.dispose();
    _ref.read(cameraScanServiceProvider).dispose();
    super.dispose();
  }
}

final scanSessionProvider =
    StateNotifierProvider.autoDispose<ScanSessionNotifier, ScanSessionState>(
  (ref) => ScanSessionNotifier(ref),
);
