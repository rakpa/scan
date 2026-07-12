import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/neu_decorations.dart';
import '../../documents/domain/entities.dart';
import '../../documents/presentation/documents_providers.dart';
import '../../scan/presentation/scan_controller.dart';

/// Dashboard home matching Stitch "Dashboard" — search, recent scans grid, FAB,
/// and bottom navigation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  bool _gridView = true;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);
    final docsAsync = ref.watch(documentListProvider);

    ref.listen(scanControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: ${next.error}')),
        );
      }
    });

    Future<void> scan() async {
      final doc = await ref.read(scanControllerProvider.notifier).scanAndSave();
      if (doc != null && context.mounted) context.push('/document/${doc.id}');
    }

    return Scaffold(
      backgroundColor: context.tokens.canvasBackground,
      body: SafeArea(
        child: Column(
          children: [
            _DashboardHeader(onSettings: () => _showSettings(context)),
            Expanded(
              child: _navIndex == 0
                  ? _ScansTab(
                      docsAsync: docsAsync,
                      query: _query,
                      gridView: _gridView,
                      onQueryChanged: (q) => setState(() => _query = q),
                      onToggleView: () => setState(() => _gridView = !_gridView),
                    )
                  : _PlaceholderTab(index: _navIndex),
            ),
          ],
        ),
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton(
              onPressed: scanState.isLoading ? null : scan,
              backgroundColor: context.colors.primary,
              foregroundColor: context.colors.onPrimary,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: scanState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_a_photo_rounded, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onChanged: (i) {
          if (i == 1) {
            context.push('/library');
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: const Text('Subscription'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/paywall');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Help'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About ScanMaster AI'),
              subtitle: const Text('Version 0.1'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: NeuDecorations.flat(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          _NeuIconButton(
            icon: Icons.menu_rounded,
            onTap: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'ScanMaster AI',
              style: context.text.titleLarge?.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _NeuIconButton(
            icon: Icons.settings_rounded,
            onTap: onSettings,
          ),
        ],
      ),
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
      color: context.colors.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: NeuDecorations.flat(),
          ),
          child: Icon(icon, color: context.colors.onSurfaceVariant, size: 22),
        ),
      ),
    );
  }
}

class _ScansTab extends StatelessWidget {
  const _ScansTab({
    required this.docsAsync,
    required this.query,
    required this.gridView,
    required this.onQueryChanged,
    required this.onToggleView,
  });

  final AsyncValue<List<DocumentSummary>> docsAsync;
  final String query;
  final bool gridView;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        100,
      ),
      children: [
        _SearchBar(query: query, onChanged: onQueryChanged),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Recent Scans', style: context.text.titleMedium),
            ),
            _ViewToggleButton(
              icon: Icons.grid_view_rounded,
              active: gridView,
              onTap: onToggleView,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ViewToggleButton(
              icon: Icons.view_list_rounded,
              active: !gridView,
              onTap: onToggleView,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        docsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Could not load documents: $e'),
          data: (docs) {
            final filtered = docs.where((d) {
              if (query.isEmpty) return true;
              return d.document.title.toLowerCase().contains(query.toLowerCase());
            }).toList();

            if (filtered.isEmpty) {
              return const _EmptyRecent();
            }

            if (gridView) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _ScanCard(summary: filtered[i]),
              );
            }

            return Column(
              children: [
                for (final doc in filtered) ...[
                  _ScanListTile(summary: doc),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.query, required this.onChanged});
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeuDecorations.card(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        pressed: true,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: context.colors.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'Search Scans...',
                hintStyle: context.text.bodyLarge?.copyWith(
                  color: context.colors.outline,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: context.text.bodyLarge,
            ),
          ),
          IconButton(
            icon: Icon(Icons.mic_rounded, color: context.colors.secondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: NeuDecorations.flat(),
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? context.colors.secondary : context.colors.outline,
          ),
        ),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.summary});
  final DocumentSummary summary;

  @override
  Widget build(BuildContext context) {
    final doc = summary.document;
    final thumb = summary.thumbnailPath;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/document/${doc.id}'),
        child: Container(
          decoration: NeuDecorations.card(color: Colors.white),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (thumb != null && File(thumb).existsSync())
                      ? Image.file(File(thumb), fit: BoxFit.cover, cacheWidth: 400)
                      : Container(
                          color: context.colors.surfaceContainerHighest,
                          child: Icon(Icons.description_outlined,
                              color: context.colors.onSurfaceVariant),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                doc.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge?.copyWith(fontSize: 12),
              ),
              Text(
                '${DateFormat.MMMd().format(doc.updatedAt)} · ${summary.pageCount} pg',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppDuration.base);
  }
}

class _ScanListTile extends StatelessWidget {
  const _ScanListTile({required this.summary});
  final DocumentSummary summary;

  @override
  Widget build(BuildContext context) {
    final doc = summary.document;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/document/${doc.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: NeuDecorations.card(color: Colors.white),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 72,
                  child: summary.thumbnailPath != null &&
                          File(summary.thumbnailPath!).existsSync()
                      ? Image.file(File(summary.thumbnailPath!), fit: BoxFit.cover)
                      : Container(
                          color: context.colors.surfaceContainerHighest,
                          child: Icon(Icons.description_outlined,
                              color: context.colors.onSurfaceVariant),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, style: context.text.titleSmall),
                    Text(
                      '${DateFormat.MMMd().format(doc.updatedAt)} · ${summary.pageCount} pages',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: NeuDecorations.card(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 48, color: context.colors.primary),
          const SizedBox(height: AppSpacing.md),
          Text('No scans yet', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tap the camera button to capture your first document.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.index});
  final int index;

  String get _label => switch (index) {
        2 => 'Search',
        3 => 'Profile',
        _ => 'Folders',
      };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded,
              size: 48, color: context.colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text('$_label coming soon', style: context.text.titleMedium),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.description_rounded, 'Scans'),
      (Icons.folder_outlined, 'Folders'),
      (Icons.search_rounded, 'Search'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  active: index == i,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: active
            ? BoxDecoration(
                color: BrandColors.secondaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: active
                  ? context.colors.primary
                  : context.colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: context.text.labelSmall?.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
