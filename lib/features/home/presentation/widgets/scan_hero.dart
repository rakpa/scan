import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/design/app_spacing.dart';

/// The primary action on the home screen: a solid dark-purple "scanner" card
/// with white corner brackets, a subtle sweeping scan line, and a white capture
/// button. Flat — no gradients or glow.
class ScanHero extends StatefulWidget {
  const ScanHero({super.key, required this.onTap, this.busy = false});

  final VoidCallback onTap;
  final bool busy;

  @override
  State<ScanHero> createState() => _ScanHeroState();
}

class _ScanHeroState extends State<ScanHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanSurface = context.tokens.scanSurface;

    return Semantics(
      button: true,
      label: 'Scan a document',
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onTap,
        child: Container(
          height: 196,
          decoration: BoxDecoration(
            color: scanSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle sweeping scan line.
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Positioned(
                  left: 26,
                  right: 26,
                  top: 34 + _controller.value * 116,
                  child: Container(
                    height: 2,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              // Corner brackets.
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CustomPaint(painter: _BracketPainter()),
                ),
              ),
              Center(child: _centerContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerContent(BuildContext context) {
    if (widget.busy) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.center_focus_strong_rounded,
              color: context.colors.primary, size: 30),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Scan document',
          style: context.text.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          'Auto edge detection',
          style: context.text.bodySmall
              ?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

/// Draws four white L-shaped corner brackets.
class _BracketPainter extends CustomPainter {
  const _BracketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const len = 24.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(Offset o, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + dx * len, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + dy * len),
        paint,
      );
    }

    corner(const Offset(0, 0), 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) => false;
}
