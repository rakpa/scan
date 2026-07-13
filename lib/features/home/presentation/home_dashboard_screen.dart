import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dashboard_chrome.dart';
import 'recent_scans_grid.dart';

/// Native home dashboard — matches the Stitch / Scanella design exactly.
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({
    super.key,
    required this.onScan,
    required this.scanBusy,
    this.onTabSelect,
    this.selectedTab = 0,
  });

  final VoidCallback onScan;
  final bool scanBusy;
  final ValueChanged<int>? onTabSelect;
  final int selectedTab;

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  var _listView = false;

  static const _primary = Color(0xFF0040A1);
  static const _secondary = Color(0xFF006A6A);
  static const _canvas = Color(0xFFF5F5F7);
  static const _surface = Color(0xFFF9F9FB);
  static const _onSurface = Color(0xFF1A1C1D);
  static const _muted = Color(0xFF737785);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: _buildSectionHeader(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RecentScansGrid(
                  listView: _listView,
                  onDocumentTap: (id) => context.push('/document/$id'),
                ),
              ),
            ),
            SizedBox(height: 80 + bottomInset),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 64 + bottomInset, right: 8),
        child: ScanFab(
          onPressed: widget.scanBusy ? null : widget.onScan,
          loading: widget.scanBusy,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: DashboardBottomNav(
        selected: widget.selectedTab,
        onSelect: widget.onTabSelect ?? (_) {},
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _NeuIconButton(
            icon: Icons.menu_rounded,
            onTap: () {},
          ),
          const Expanded(
            child: Text(
              'Scanella',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: _primary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          _NeuIconButton(
            icon: Icons.settings_rounded,
            onTap: () => widget.onTabSelect?.call(3),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(4, 4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: _muted, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Search Scans...',
              style: TextStyle(fontSize: 16, color: _muted),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.mic_rounded, color: _secondary, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Text(
            'Recent Scans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _onSurface,
            ),
          ),
        ),
        _ViewToggle(
          gridSelected: !_listView,
          onGrid: () => setState(() => _listView = false),
          onList: () => setState(() => _listView = true),
        ),
      ],
    );
  }
}

class _NeuIconButton extends StatelessWidget {
  const _NeuIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9F9FB),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(4, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF424654), size: 22),
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.gridSelected,
    required this.onGrid,
    required this.onList,
  });

  final bool gridSelected;
  final VoidCallback onGrid;
  final VoidCallback onList;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleBtn(
          icon: Icons.grid_view_rounded,
          selected: gridSelected,
          onTap: onGrid,
        ),
        const SizedBox(width: 8),
        _ToggleBtn(
          icon: Icons.view_list_rounded,
          selected: !gridSelected,
          onTap: onList,
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF90EFEF).withValues(alpha: 0.25) : const Color(0xFFF9F9FB),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(4, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: selected ? const Color(0xFF006A6A) : const Color(0xFF737785),
          ),
        ),
      ),
    );
  }
}
