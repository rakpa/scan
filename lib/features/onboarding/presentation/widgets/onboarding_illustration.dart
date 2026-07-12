import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/design/app_color_tokens.dart';

enum OnboardingArt { scanFrame, pdfFile, shareCard }

/// Flat, brand-purple feature illustrations for the onboarding slides — drawn
/// in code to match the reference layout without external assets.
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({super.key, required this.art});

  final OnboardingArt art;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: 260,
      child: Center(child: _build(context)),
    );
  }

  Widget _build(BuildContext context) {
    switch (art) {
      case OnboardingArt.scanFrame:
        return const _ScanFrameArt();
      case OnboardingArt.pdfFile:
        return const _PdfFileArt();
      case OnboardingArt.shareCard:
        return const _ShareCardArt();
    }
  }
}

/// A document framed by indigo scan brackets with a scan line.
class _ScanFrameArt extends StatelessWidget {
  const _ScanFrameArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: CustomPaint(
        painter: _ScanFramePainter(
          bracket: BrandColors.primary,
          paper: context.colors.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter({required this.bracket, required this.paper});
  final Color bracket;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paperRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.2, w * 0.44, h * 0.6),
      const Radius.circular(10),
    );
    canvas.drawRRect(paperRect, Paint()..color = paper);

    final fold = Path()
      ..moveTo(w * 0.62, h * 0.2)
      ..lineTo(w * 0.72, h * 0.2)
      ..lineTo(w * 0.72, h * 0.3)
      ..close();
    canvas.drawPath(fold, Paint()..color = const Color(0xFFE9E6FF));

    final line = Paint()
      ..color = bracket
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.4 + i * 0.07);
      canvas.drawLine(Offset(w * 0.36, y), Offset(w * 0.6, y), line);
    }

    canvas.drawLine(
      Offset(w * 0.24, h * 0.62),
      Offset(w * 0.76, h * 0.62),
      Paint()
        ..color = bracket
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    final br = Paint()
      ..color = bracket
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const len = 34.0;
    void corner(Offset o, double dx, double dy) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx + dx * len, o.dy)
          ..lineTo(o.dx, o.dy)
          ..lineTo(o.dx, o.dy + dy * len),
        br,
      );
    }

    corner(Offset(w * 0.12, h * 0.12), 1, 1);
    corner(Offset(w * 0.88, h * 0.12), -1, 1);
    corner(Offset(w * 0.12, h * 0.88), 1, -1);
    corner(Offset(w * 0.88, h * 0.88), -1, -1);
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => false;
}

/// A violet PDF file icon.
class _PdfFileArt extends StatelessWidget {
  const _PdfFileArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 188,
      decoration: BoxDecoration(
        color: const Color(0xFFC7BEFF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BrandColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFE9E6FF),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18)),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    size: 56, color: BrandColors.primaryDeep),
                const SizedBox(height: 6),
                Text(
                  'PDF',
                  style: context.text.titleLarge?.copyWith(
                    color: BrandColors.primaryDeep,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card with connected share nodes, plus an offset back card.
class _ShareCardArt extends StatelessWidget {
  const _ShareCardArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 150,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E6FF),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Container(
            width: 150,
            height: 180,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrandColors.primary, width: 1.5),
            ),
            child: CustomPaint(painter: _ShareNodesPainter()),
          ),
        ],
      ),
    );
  }
}

class _ShareNodesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(size.width * 0.34, size.height * 0.5);
    final b = Offset(size.width * 0.66, size.height * 0.32);
    final c = Offset(size.width * 0.66, size.height * 0.68);

    final link = Paint()
      ..color = BrandColors.primaryBright
      ..strokeWidth = 3;
    canvas.drawLine(a, b, link);
    canvas.drawLine(a, c, link);

    void node(Offset o, Color color, double r) {
      canvas.drawCircle(o, r, Paint()..color = color);
    }

    node(a, BrandColors.primary, 13);
    node(b, BrandColors.primaryBright, 11);
    node(c, const Color(0xFFA78BFA), 11);
  }

  @override
  bool shouldRepaint(_ShareNodesPainter oldDelegate) => false;
}
