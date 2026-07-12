import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';
import '../../scan/presentation/scan_controller.dart';

/// Main shell — Stitch Dashboard HTML with native scan FAB + bottom-nav hotspots.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _tab;
  var _htmlReady = false;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  String get _html => switch (_tab) {
        3 => StitchScreens.settings,
        _ => StitchScreens.dashboard,
      };

  Future<void> _scan() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning runs on the installed app.')),
      );
      return;
    }

    final doc = await ref.read(scanControllerProvider.notifier).scanAndSave();
    if (!mounted) return;
    if (doc != null) context.push('/document/${doc.id}');
  }

  void _selectTab(int i) {
    setState(() {
      _tab = i;
      _htmlReady = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);
    final scanning = scanState.isLoading;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          StitchHtmlView(
            htmlAsset: _html,
            backgroundColor: const Color(0xFFF5F5F7),
            interactive: false,
            onLoaded: () {
              if (mounted) setState(() => _htmlReady = true);
            },
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
          if (_htmlReady && _tab <= 1)
            Positioned(
              right: 24,
              bottom: 88 + bottomInset,
              child: _ScanFab(
                onPressed: scanning ? null : _scan,
                loading: scanning,
              ),
            ),
          if (scanning)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Opening scanner…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
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
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
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
