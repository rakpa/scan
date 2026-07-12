import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/neu_decorations.dart';
import '../../../shared/widgets/stitch/stitch_widgets.dart';

/// Stitch Settings screen.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.embedded = false});

  /// When true, rendered inside [MainShell] without its own back button.
  final bool embedded;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saveToGallery = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.embedded)
          StitchDashboardHeader(onTrailing: () {})
        else
          StitchDashboardHeader(
            trailingIcon: Icons.arrow_back_rounded,
            onTrailing: () => context.pop(),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Settings', style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Manage your ScanMaster AI preferences and account details.',
                style: context.text.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('Account'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile Info',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Subscription',
                    subtitle: 'Free Plan',
                    onTap: () => context.push('/paywall'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('General'),
              _SettingsGroup(
                children: [
                  _SettingsSwitch(
                    icon: Icons.photo_library_outlined,
                    title: 'Save to Gallery',
                    subtitle: 'Automatically save scans to photos',
                    value: _saveToGallery,
                    onChanged: (v) => setState(() => _saveToGallery = v),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('Import & Export'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.upload_file_outlined,
                    title: 'Default Export Format',
                    subtitle: 'PDF',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionTitle('About'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About ScanMaster AI',
                    subtitle: 'Version 0.1.0',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: context.text.titleSmall?.copyWith(color: context.colors.primary),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: NeuDecorations.card(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: context.colors.outlineVariant.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.colors.primary, size: 20),
      ),
      title: Text(title, style: context.text.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle!, style: context.text.bodySmall)
          : null,
      trailing: Icon(Icons.chevron_right_rounded,
          color: context.colors.onSurfaceVariant),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.colors.primary,
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.colors.primary, size: 20),
      ),
      title: Text(title, style: context.text.bodyLarge),
      subtitle: Text(subtitle, style: context.text.bodySmall),
    );
  }
}
