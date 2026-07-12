import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_color_tokens.dart';
import '../../../core/design/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../onboarding/data/onboarding_store.dart';

class _Slide {
  const _Slide({
    required this.imageAsset,
    required this.title,
    required this.body,
  });

  final String? imageAsset;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    imageAsset: 'assets/images/onboarding_auto_crop.png',
    title: 'Smart Auto-Crop',
    body: 'Automatically detects and crops your documents perfectly.',
  ),
  _Slide(
    imageAsset: null,
    title: 'Filter & Enhance',
    body: 'Apply Magic Color, B&W, and brightness adjustments for crisp scans.',
  ),
  _Slide(
    imageAsset: null,
    title: 'Export & Share',
    body: 'Create multi-page PDFs and share anywhere in seconds.',
  ),
];

/// Onboarding flow matching Stitch "Onboarding - Auto-Crop" layout.
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
      context.go('/paywall');
    } else {
      _controller.nextPage(
        duration: AppDuration.base,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _skip() async {
    final store = await ref.read(onboardingStoreProvider.future);
    await store.markComplete();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideView(slide: _slides[i], index: i),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: PrimaryButton(
                label: _isLast ? 'Get Started' : 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
            TextButton(
              onPressed: _skip,
              child: Text(
                'Skip',
                style: context.text.labelLarge?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: slide.imageAsset != null
                  ? Image.asset(
                      slide.imageAsset!,
                      fit: BoxFit.contain,
                    )
                  : _FallbackIllustration(index: index),
            ),
          ),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _FallbackIllustration extends StatelessWidget {
  const _FallbackIllustration({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final icon = index == 1 ? Icons.tune_rounded : Icons.picture_as_pdf_rounded;
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: BrandColors.primaryFixed.withValues(alpha: 0.4),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 80, color: BrandColors.primary),
    );
  }
}

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
            color: active
                ? context.colors.primary
                : context.colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
