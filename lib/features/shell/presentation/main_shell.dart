import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';
import '../../home/presentation/recent_scans_grid.dart';
import '../../scan/presentation/scan_controller.dart';

/// Main shell — Stitch chrome + native recent scans grid + reliable scan FAB.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _tab;
  var _scanBusy = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  String get _html => switch (_tab) {
        3 => StitchScreens.settings,
        _ => StitchScreens.dashboard,
      };

  bool get _showScansGrid => _tab == 0;

  Future<void> _scan() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning runs on the installed app.')),
      );
      return;
    }
    if (_scanBusy) return;

    setState(() => _scanBusy = true);
    try {
      // Do not show a full-screen overlay here — it blocks the native scanner
      // from presenting on iOS when a WebView is underneath.
      final doc = await ref.read(scanControllerProvider.notifier).scanAndSave();
      if (!mounted) return;
      if (doc != null) context.push('/document/${doc.id}');
    } finally {
      if (mounted) setState(() => _scanBusy = false);
    }
  }

  void _selectTab(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    // Grid sits below header + search (~200px from top on most phones).
    final gridTop = topInset + 196;
    final gridBottom = 88 + bottomInset;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          StitchHtmlView(
            htmlAsset: _html,
            backgroundColor: const Color(0xFFF5F5F7),
            interactive: false,
            hideDemoContent: _showScansGrid,
            hotspots: [
              StitchHotspot(
                left: 0.02,
                top: 0.88,
                width: 0.22,
                height: 0.10,
                semanticLabel: 'Scans',
                onTap: () => _selectTab(0),
              ),
              StitchHotspot(
                left: 0.26,
                top: 0.88,
                width: 0.22,
                height: 0.10,
                semanticLabel: 'Folders',
                onTap: () => _selectTab(1),
              ),
              StitchHotspot(
                left: 0.50,
                top: 0.88,
                width: 0.22,
                height: 0.10,
                semanticLabel: 'Search',
                onTap: () => _selectTab(2),
              ),
              StitchHotspot(
                left: 0.74,
                top: 0.88,
                width: 0.22,
                height: 0.10,
                semanticLabel: 'Profile',
                onTap: () => _selectTab(3),
              ),
              if (_tab == 0)
                StitchHotspot(
                  left: 0.78,
                  top: 0.01,
                  width: 0.18,
                  height: 0.08,
                  semanticLabel: 'Settings',
                  onTap: () => _selectTab(3),
                ),
              if (_tab == 3)
                StitchHotspot(
                  left: 0.05,
                  top: 0.10,
                  width: 0.9,
                  height: 0.12,
                  semanticLabel: 'Subscription',
                  onTap: () => context.push('/paywall'),
                ),
            ],
          ),
          if (_showScansGrid)
            Positioned(
              left: 16,
              right: 16,
              top: gridTop,
              bottom: gridBottom,
              child: RecentScansGrid(
                onDocumentTap: (id) => context.push('/document/$id'),
              ),
            ),
          if (_tab <= 1)
            Positioned(
              right: 24,
              bottom: 88 + bottomInset,
              child: _ScanFab(
                onPressed: _scanBusy ? null : _scan,
                loading: _scanBusy,
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onPressed, required this.loading});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: const Color(0xFF0040A1).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF0040A1),
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 64,
          height: 64,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.add_a_photo_rounded,
                  color: Colors.white,
                  size: 30,
                ),
        ),
      ),
    );
  }
}
