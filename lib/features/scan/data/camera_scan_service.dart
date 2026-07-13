import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Manages the device camera for live preview and capture.
class CameraScanService {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    if (kIsWeb) return;

    final granted = await _ensureCameraPermission();
    if (!granted) {
      throw StateError(
        'Camera permission is required to scan documents. '
        'Enable it in Settings and try again.',
      );
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw StateError('No camera found on this device.');
    }

    final back = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    final controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    await controller.setFocusMode(FocusMode.auto);
    await controller.setExposureMode(ExposureMode.auto);
    _controller = controller;
  }

  Future<bool> toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return false;

    final next = controller.value.flashMode == FlashMode.torch
        ? FlashMode.off
        : FlashMode.torch;
    await controller.setFlashMode(next);
    return next == FlashMode.torch;
  }

  Future<String> capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Camera is not ready.');
    }
    final file = await controller.takePicture();
    return file.path;
  }

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (controller.value.flashMode == FlashMode.torch) {
        await controller.setFlashMode(FlashMode.off);
      }
      await controller.dispose();
    }
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    status = await Permission.camera.request();
    return status.isGranted;
  }
}
