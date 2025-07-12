import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class ShaderVisualizer extends StatefulWidget {
  const ShaderVisualizer({super.key});

  @override
  State<ShaderVisualizer> createState() => _ShaderVisualizerState();
}

class _ShaderVisualizerState extends State<ShaderVisualizer> {
  late Timer timer;
  double _time = 0;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShader();
    timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _time += 0.016;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> _loadShader() async {
    final program = await FragmentProgram.fromAsset('shaders/visualizer.frag');
    _shader = program.fragmentShader();
    setState(() {
      // Shader is loaded, trigger a repaint
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return CustomPaint(
      painter: ShaderPainter(_shader!, _time),
      child: Container(),
    );
  }
}

class ShaderPainter extends CustomPainter {
  ShaderPainter(this.shader, this.time);

  final FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
