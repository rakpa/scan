import 'package:flutter/material.dart';

import '../../core/design/app_color_tokens.dart';

/// The app logo mark — a flat purple rounded square framed by white scan
/// brackets, holding a white document with purple text lines and a small red
/// "2026" ribbon. No gradients.
///
/// The Android launch screen draws a matching version so the mark appears the
/// instant the app opens (see res/drawable/logo_glyph.xml).
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 120, this.showRibbon = true});

  final double size;
  final bool showRibbon;

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: BrandColors.purpleBright,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: size * 0.14,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.all(size * 0.16),
              child: CustomPaint(
                painter: _ScanBracketPainter(),
                child: Center(child: _DocumentMark(size: size * 0.42)),
              ),
            ),
          ),
          if (showRibbon)
            Positioned(
              top: size * 0.07,
              right: -size * 0.01,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size * 0.07,
                  vertical: size * 0.03,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8362F),
                  borderRadius: BorderRadius.circular(size * 0.06),
                ),
                child: Text(
                  '2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White document card with purple text lines and a folded corner.
class _DocumentMark extends StatelessWidget {
  const _DocumentMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.28,
      child: CustomPaint(painter: _DocumentPainter()),
    );
  }
}

class _DocumentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fold = w * 0.28;
    final r = w * 0.10;

    final body = Path()
      ..moveTo(r, 0)
      ..lineTo(w - fold, 0)
      ..lineTo(w, fold)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.white);

    final foldPath = Path()
      ..moveTo(w - fold, 0)
      ..lineTo(w - fold, fold)
      ..lineTo(w, fold)
      ..close();
    canvas.drawPath(foldPath, Paint()..color = const Color(0xFFE9E6FF));

    final line = Paint()
      ..color = BrandColors.purple
      ..strokeWidth = h * 0.045
      ..strokeCap = StrokeCap.round;
    final left = w * 0.18;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.52 + i * 0.13);
      final right = i == 1 ? w * 0.66 : w * 0.82;
      canvas.drawLine(Offset(left, y), Offset(right, y), line);
    }
  }

  @override
  bool shouldRepaint(_DocumentPainter oldDelegate) => false;
}

/// Four white L-shaped scan brackets framing the document.
class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final len = size.width * 0.22;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.06
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
  bool shouldRepaint(_ScanBracketPainter oldDelegate) => false;
}
