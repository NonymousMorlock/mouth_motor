import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tts_app/shader_visualizer.dart';
import 'package:tts_app/tts_controls.dart';

class NewHomePage extends StatelessWidget {
  const NewHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ShaderVisualizer(),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Read Aloud',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fade(duration: 500.ms).slideY(begin: -0.5),
                    const SizedBox(height: 40),
                    // Placeholder for controls
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const TtsControls(),
                    )
                        .animate()
                        .fade(delay: 300.ms, duration: 500.ms)
                        .slideY(begin: 0.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
