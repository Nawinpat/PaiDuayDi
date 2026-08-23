import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double textSize;

  const BrandLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.textSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Real App Icon
        ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            'assets/images/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _BrandLogoPainter(),
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'PaiDuayDi',
            style: AppTypography.brandTitle.copyWith(
              fontSize: textSize,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _BrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final startPoint = Offset(w * 0.25, h * 0.75);
    final endPoint = Offset(w * 0.75, h * 0.25);

    final linePaint = Paint()
      ..color = AppColors.borderGreen
      ..strokeWidth = w * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(
        w * 0.45, h * 0.75,
        w * 0.55, h * 0.25,
        endPoint.dx, endPoint.dy,
      );

    canvas.drawPath(path, linePaint);

    // Green Node
    final greenOuterPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final greenInnerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(startPoint, w * 0.16, greenOuterPaint);
    canvas.drawCircle(startPoint, w * 0.11, greenInnerPaint);
    canvas.drawCircle(startPoint, w * 0.05, whitePaint);

    // Orange Node
    final orangeOuterPaint = Paint()
      ..color = AppColors.accentOrange.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final orangeInnerPaint = Paint()
      ..color = AppColors.accentOrange
      ..style = PaintingStyle.fill;

    canvas.drawCircle(endPoint, w * 0.16, orangeOuterPaint);
    canvas.drawCircle(endPoint, w * 0.11, orangeInnerPaint);
    canvas.drawCircle(endPoint, w * 0.05, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
