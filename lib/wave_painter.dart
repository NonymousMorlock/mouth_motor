import 'dart:typed_data';

import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  const WavePainter({
    required this.data,
  });

  final Float32List data;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / data.length;
    final paint = Paint()
      ..color = Colors.yellowAccent
      ..strokeWidth = barWidth;

    for (var i = 0; i < data.length; i++) {
      final barHeight = size.height * data[i] * 2;
      canvas.drawLine(
        Offset(barWidth * i, (size.height - barHeight) / 2),
        Offset(barWidth * i, (size.height + barHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }
}