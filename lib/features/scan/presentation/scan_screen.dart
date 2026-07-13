import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/scan_mode.dart';
import 'scan_controller.dart';
import 'scan_design_tokens.dart';
import 'scan_session_controller.dart';
import 'widgets/scan_bottom_controls.dart';
import 'widgets/scan_edge_overlay.dart';
import 'widgets/scan_mode_selector.dart';
import 'widgets/scan_review_panel.dart';
import 'widgets/scan_status_pill.dart';
import 'widgets/scan_top_toolbar.dart';

/// Premium in-app camera scanner with live edge guides and multi-page capture.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.args = const ScanRouteArgs()});

  final ScanRouteArgs args;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _detectionTimer;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kIsWeb) return;
      await ref.read(scanSessionProvider.notifier).initializeCamera();
      _detectionTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => ref.read(scanSessionProvider.notifier).updateDetection(),
      );
      if (widget.args.openGallery && mounted) {
        await ref.read(scanSessionProvider.notifier).importFromGallery();
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      await HapticFeedback.lightImpact();
      await ref.read(scanSessionProvider.notifier).capture(manual: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture failed: $e')),
      );
    }
  }

  Future<void> _save() async {
    final paths = ref.read(scanSessionProvider).capturedPaths;
    if (paths.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      final controller = ref.read(scanControllerProvider.notifier);
      final appendId = widget.args.appendDocumentId;

      if (appendId != null) {
        final ok = await controller.saveAppendedPages(appendId, paths);
        if (!mounted) return;
        if (ok) {
          context.pop(true);
        }
      } else {
        final doc = await controller.saveFromPaths(
          paths,
          folderId: widget.args.folderId,
        );
        if (!mounted) return;
        if (doc != null) {
          context.pop();
          context.push('/document/${doc.id}');
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _launchNativeScanner() async {
    final controller = ref.read(scanControllerProvider.notifier);
    final appendId = widget.args.appendDocumentId;

    if (appendId != null) {
      final ok = await controller.scanAndAppend(appendId);
      if (!mounted) return;
      if (ok) context.pop(true);
    } else {
      final doc = await controller.scanAndSave(folderId: widget.args.folderId);
      if (!mounted) return;
      if (doc != null) {
        context.pop();
        context.push('/document/${doc.id}');
      }
    }
  }

  void _showMoreMenu() {
    final session = ref.read(scanSessionProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1C1D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Auto-capture', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Capture when document is stable',
                style: TextStyle(color: Colors.white70),
              ),
              value: session.autoCapture,
              activeThumbColor: ScanDesign.primary,
              onChanged: (v) =>
                  ref.read(scanSessionProvider.notifier).setAutoCapture(v),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined, color: Colors.white),
              title: const Text('System scanner', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Use native ML Kit / VisionKit UI',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _launchNativeScanner();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scanner'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Camera scanning runs on the installed app.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final session = ref.watch(scanSessionProvider);
    final camera = ref.read(scanSessionProvider.notifier).cameraController;

    if (session.step == ScanStep.review) {
      return ScanReviewPanel(
        paths: session.capturedPaths,
        saving: _saving,
        onBack: () => ref.read(scanSessionProvider.notifier).backToCapture(),
        onRemove: (i) => ref.read(scanSessionProvider.notifier).removePage(i),
        onAddMore: () => ref.read(scanSessionProvider.notifier).backToCapture(),
        onSave: _save,
      );
    }

    final quad = session.quad ?? DocumentQuad.forMode(session.mode);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (session.cameraReady && camera != null && camera.value.isInitialized)
            CameraPreview(camera)
          else if (session.cameraError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  session.cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: ScanDesign.primary),
            ),

          if (session.cameraReady)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => ScanEdgeOverlay(
                quad: quad,
                confidence: session.confidence,
                pulse: _pulseController.value,
              ),
            ),

          if (session.showFlashOverlay)
            AnimatedOpacity(
              opacity: session.showFlashOverlay ? 1 : 0,
              duration: const Duration(milliseconds: 80),
              child: const ColoredBox(color: Colors.white),
            ),

          // Glass bottom gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 280,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              ScanTopToolbar(
                onClose: () => context.pop(),
                onFlash: () => ref.read(scanSessionProvider.notifier).toggleFlash(),
                onMore: _showMoreMenu,
                flashOn: session.flashOn,
                status: session.phase,
              ),
              const Spacer(),
              ScanStatusPill(
                phase: session.phase,
                confidence: session.confidence,
              ),
              const SizedBox(height: 16),
              ScanModeSelector(
                selected: session.mode,
                onSelected: (m) =>
                    ref.read(scanSessionProvider.notifier).setMode(m),
              ),
              const SizedBox(height: 12),
              ScanBottomControls(
                pageCount: session.pageCount,
                capturing: session.isCapturing,
                onGallery: () =>
                    ref.read(scanSessionProvider.notifier).importFromGallery(),
                onCapture: _capture,
                onDone: () => ref.read(scanSessionProvider.notifier).goToReview(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
