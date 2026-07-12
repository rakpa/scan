import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../shared/widgets/stitch/stitch_frame.dart';
import '../../scan/presentation/scan_controller.dart';

/// Main shell — Stitch Dashboard PNG with scan FAB + bottom-nav hotspots.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _tab;
  bool _showCapturePreview = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  String get _asset => switch (_tab) {
        3 => StitchAssets.settings,
        _ => StitchAssets.dashboard,
      };

  Future<void> _scan() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning runs on the installed app.')),
      );
      return;
    }
    setState(() => _showCapturePreview = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final doc = await ref.read(scanControllerProvider.notifier).scanAndSave();
    if (!mounted) return;
    setState(() => _showCapturePreview = false);
    if (doc != null) context.push('/document/${doc.id}');
  }

  void _selectTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
        setState(() => _showCapturePreview = false);
      }
    });

    if (_showCapturePreview || scanState.isLoading) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            StitchFrame(
              asset: StitchAssets.smartCapture,
              backgroundColor: Colors.black,
              fit: BoxFit.cover,
            ),
            if (scanState.isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: StitchFrame(
        asset: _asset,
        backgroundColor: const Color(0xFFF5F5F7),
        hotspots: [
          // FAB — camera / scan
          if (_tab <= 1)
            StitchHotspot(
              left: 0.72,
              top: 0.78,
              width: 0.22,
              height: 0.12,
              semanticLabel: 'Scan document',
              onTap: _scan,
            ),
          // Bottom nav — Scans
          StitchHotspot(
            left: 0.02,
            top: 0.905,
            width: 0.22,
            height: 0.09,
            semanticLabel: 'Scans',
            onTap: () => _selectTab(0),
          ),
          // Folders
          StitchHotspot(
            left: 0.26,
            top: 0.905,
            width: 0.22,
            height: 0.09,
            semanticLabel: 'Folders',
            onTap: () => _selectTab(1),
          ),
          // Search
          StitchHotspot(
            left: 0.50,
            top: 0.905,
            width: 0.22,
            height: 0.09,
            semanticLabel: 'Search',
            onTap: () => _selectTab(2),
          ),
          // Profile / Settings
          StitchHotspot(
            left: 0.74,
            top: 0.905,
            width: 0.22,
            height: 0.09,
            semanticLabel: 'Profile',
            onTap: () => _selectTab(3),
          ),
          // Settings gear (top-right on dashboard)
          if (_tab == 0)
            StitchHotspot(
              left: 0.82,
              top: 0.045,
              width: 0.14,
              height: 0.07,
              semanticLabel: 'Settings',
              onTap: () => _selectTab(3),
            ),
        ],
      ),
    );
  }
}
