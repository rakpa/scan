import 'package:flutter/material.dart';

import '../../core/design/app_color_tokens.dart';

/// ScanMaster AI logo mark — blue rounded square with white scan brackets
/// and document icon, matching the Stitch premium logo.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 120, this.showRibbon = false});

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
              color: BrandColors.primaryContainer,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: BrandColors.primary.withValues(alpha: 0.35),
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
        ],
      ),
    );
  }
}

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
    canvas.drawPath(foldPath, Paint()..color = BrandColors.primaryFixed);

    final line = Paint()
      ..color = BrandColors.primary
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
