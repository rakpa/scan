import 'package:flutter/material.dart';

/// Shared bottom nav + scan FAB used on the home dashboard.
class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.description_rounded,
              label: 'Scans',
              selected: selected == 0,
              onTap: () => onSelect(0),
            ),
            _NavItem(
              icon: Icons.folder_rounded,
              label: 'Folders',
              selected: selected == 1,
              onTap: () => onSelect(1),
            ),
            _NavItem(
              icon: Icons.search_rounded,
              label: 'Search',
              selected: selected == 2,
              onTap: () => onSelect(2),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: selected == 3,
              onTap: () => onSelect(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFF90EFEF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? const Color(0xFF0040A1)
                  : const Color(0xFF424654).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? const Color(0xFF0040A1)
                    : const Color(0xFF424654).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanFab extends StatelessWidget {
  const ScanFab({super.key, required this.onPressed, required this.loading});

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      shadowColor: const Color(0xFF0040A1).withValues(alpha: 0.4),
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
