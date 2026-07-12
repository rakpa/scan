import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../documents/presentation/document_list_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../scan/presentation/scan_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';

/// Main app shell with Stitch bottom navigation.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  Future<void> _scan() async {
    final doc = await ref.read(scanControllerProvider.notifier).scanAndSave();
    if (doc != null && mounted) context.push('/document/${doc.id}');
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: context.tokens.canvasBackground,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeTab(onScan: _scan, scanBusy: scanState.isLoading),
          DocumentListTab(onScan: _scan, scanBusy: scanState.isLoading),
          const _SearchTab(),
          const SettingsScreen(embedded: true),
        ],
      ),
      floatingActionButton: _tab <= 1
          ? StitchScanFab(onTap: _scan, busy: scanState.isLoading)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: StitchBottomNav(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StitchDashboardHeader(onMenu: () {}),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded,
                      size: 48, color: context.colors.primary),
                  const SizedBox(height: 16),
                  Text('Search', style: context.text.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Use the search bar on the Scans tab to filter your documents.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
