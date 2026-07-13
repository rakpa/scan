import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/stitch_assets.dart';
import '../../../core/design/stitch_screens.dart';
import '../../../shared/widgets/stitch/stitch_html_view.dart';
import '../../home/presentation/dashboard_chrome.dart';
import '../../home/presentation/home_dashboard_screen.dart';
import '../../scan/presentation/scan_controller.dart';

/// App shell — native home dashboard + settings HTML for profile tab.
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
    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    if (_tab == 0) {
      return HomeDashboardScreen(
        onScan: _scan,
        scanBusy: _scanBusy,
        onTabSelect: _selectTab,
        selectedTab: _tab,
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: switch (_tab) {
        1 => const _ComingSoonTab(
            icon: Icons.folder_rounded,
            title: 'Folders',
            subtitle: 'Organize scans into folders — coming soon.',
          ),
        2 => const _ComingSoonTab(
            icon: Icons.search_rounded,
            title: 'Search',
            subtitle: 'Find any scan by name — coming soon.',
          ),
        3 => StitchHtmlView(
            htmlAsset: StitchScreens.settings,
            backgroundColor: const Color(0xFFF5F5F7),
            interactive: false,
            hotspots: [
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
        _ => const SizedBox.shrink(),
      },
      floatingActionButton: _tab <= 1
          ? Padding(
              padding: EdgeInsets.only(bottom: 64 + bottomInset, right: 8),
              child: ScanFab(
                onPressed: _scanBusy ? null : _scan,
                loading: _scanBusy,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: DashboardBottomNav(
        selected: _tab,
        onSelect: _selectTab,
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: const Color(0xFF737785)),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF737785)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
