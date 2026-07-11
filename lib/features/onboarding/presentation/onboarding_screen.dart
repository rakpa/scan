import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import 'widgets/onboarding_illustration.dart';

/// A feature chip shown in a slide's action row.
class _Action {
  const _Action(this.icon, this.label, {this.fill, this.iconColor});
  final IconData icon;
  final String label;

  /// Non-null → rendered as a filled "highlighted" pill.
  final Color? fill;

  /// Tints the icon for app-tile style rows (slide 3).
  final Color? iconColor;
}

class _Slide {
  const _Slide({
    required this.art,
    required this.actions,
    required this.title,
    required this.body,
    this.tiles = false,
  });

  final OnboardingArt art;
  final List<_Action> actions;
  final String title;
  final String body;

  /// When true, actions render as white app tiles (slide 3) rather than a bar.
  final bool tiles;
}

const _slides = <_Slide>[
  _Slide(
    art: OnboardingArt.scanFrame,
    actions: [
      _Action(Icons.center_focus_strong_rounded, 'Scan', fill: BrandColors.purple),
      _Action(Icons.ios_share_rounded, 'Import'),
      _Action(Icons.image_outlined, 'Image'),
      _Action(Icons.print_outlined, 'Print'),
    ],
    title: 'All PDF tools',
    body:
        'Make, edit, convert and enhance your documents in one convenient application.',
  ),
  _Slide(
    art: OnboardingArt.pdfFile,
    actions: [
      _Action(Icons.brush_rounded, 'Highlight', fill: BrandColors.amber),
      _Action(Icons.checklist_rounded, 'Recorder'),
      _Action(Icons.note_add_outlined, 'Add Pages'),
      _Action(Icons.text_fields_rounded, 'Extract'),
    ],
    title: 'PDF Editing',
    body:
        'Experience the ultimate freedom to edit, modify and manage your PDF documents seamlessly.',
  ),
  _Slide(
    art: OnboardingArt.shareCard,
    tiles: true,
    actions: [
      _Action(Icons.cloud_upload_rounded, 'Drive', iconColor: Color(0xFF1FA463)),
      _Action(Icons.chat_rounded, 'Whatsapp', iconColor: Color(0xFF25D366)),
      _Action(Icons.mail_rounded, 'Gmail', iconColor: Color(0xFFEA4335)),
      _Action(Icons.cloud_rounded, 'iCloud', iconColor: Color(0xFF3693F3)),
    ],
    title: 'PDF Sharing',
    body:
        'Share your PDFs directly from the app through email, messaging, or cloud services like Google Drive.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      // Onboarding done → show the subscription screen (UI only).
      context.go('/paywall');
    } else {
      _controller.nextPage(
        duration: AppDuration.base,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) =>
                    _SlideView(slide: _slides[i], index: i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xs,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: PrimaryButton(label: 'Continue', onPressed: _next),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.index});
  final _Slide slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          OnboardingIllustration(art: slide.art),
          const SizedBox(height: AppSpacing.xl),
          if (slide.tiles)
            _AppTiles(actions: slide.actions)
          else
            _ActionBar(actions: slide.actions),
          const SizedBox(height: AppSpacing.xl),
          _Dots(count: _slides.length, index: index),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: context.text.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Pill-style action bar (slides 1–2): one filled pill + outline icon items.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.actions});
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final a in actions)
            if (a.fill != null)
              _FilledPill(action: a)
            else
              _IconLabel(action: a),
        ],
      ),
    );
  }
}

class _FilledPill extends StatelessWidget {
  const _FilledPill({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    final fill = action.fill!;
    final onFill = fill == BrandColors.amber ? BrandColors.purpleDeep : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(action.icon, size: 20, color: onFill),
          const SizedBox(width: 8),
          Text(
            action.label,
            style: context.text.labelLarge?.copyWith(color: onFill),
          ),
        ],
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.action});
  final _Action action;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(action.icon, size: 24, color: context.colors.onSurfaceVariant),
        const SizedBox(height: 4),
        Text(
          action.label,
          style: context.text.bodySmall
              ?.copyWith(color: context.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// App-tile row (slide 3): white tiles with colored brand icons + labels.
class _AppTiles extends StatelessWidget {
  const _AppTiles({required this.actions});
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final a in actions)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(a.icon, color: a.iconColor, size: 28),
                ),
                const SizedBox(height: 6),
                Text(a.label, style: context.text.bodySmall),
              ],
            ),
        ],
      ),
    );
  }
}

/// Page-progress dots (active dot is an indigo pill).
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppDuration.base,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 24 : 8,
          decoration: BoxDecoration(
            color: active ? context.colors.primary : context.colors.outlineVariant,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}
