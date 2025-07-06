import 'dart:typed_data';

import 'package:flutter/material.dart';

class AudioVisualizerPainter extends CustomPainter {
  final Float32List samples;
  final Paint barPaint;

  AudioVisualizerPainter({
    required this.samples,
  }) : barPaint = Paint()..color = Colors.blue.withValues(alpha: .2);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    // We're only interested in FFT data (first 256 values)
    final fftData = samples.sublist(0, 256);
    final barWidth = size.width / fftData.length;

    for (var i = 0; i < fftData.length; i++) {
      // FFT data typically contains values between 0.0 and 1.0
      final barHeight = fftData[i] * size.height;

      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,           // Left position
          size.height - barHeight, // Top position (from bottom)
          barWidth,               // Width of each bar
          barHeight,              // Height of each bar
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AudioVisualizerPainter oldDelegate) {
    return true; // Always repaint when new data arrives
  }
}
