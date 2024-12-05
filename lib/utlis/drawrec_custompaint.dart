import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RectanglePainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;

  RectanglePainter({this.startPoint, this.endPoint});
  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromPoints(startPoint!, endPoint!);
    canvas.drawRect(rect, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
