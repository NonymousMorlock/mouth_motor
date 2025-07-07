import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:tts_app/child_builder.dart';
import 'package:tts_app/tts_service.dart';

class TtsControls extends StatefulWidget {
  const TtsControls({super.key});

  @override
  State<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends State<TtsControls> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _ttsService = TtsService.instance;

  double _speed = 1.0;
  bool _useSSML = false;
  bool _isAsync = false;

  @override
  void initState() {
    super.initState();
    _ttsService.fetchSpeakers();
    _ttsService.startPolling();
    SoLoud.instance.setVisualizationEnabled(true);
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isAsync) {
      await _ttsService.synthesizeAsync(
        text: _controller.text,
        speaker: _ttsService.selectedSpeaker.value,
        speed: _speed,
        ssml: _useSSML,
      );
    } else {
      await _speak();
    }
  }

  Future<void> _speak() async {
    if (_controller.text.isEmpty || _ttsService.selectedSpeaker.value == null) {
      return;
    }

    final audioData = await _ttsService.synthesizeSync(
      text: _controller.text,
      speaker: _ttsService.selectedSpeaker.value,
      speed: _speed,
      ssml: _useSSML,
    );

    if (audioData != null) {
      await _audioPlayer.play(BytesSource(audioData));
    } else {
      _showError('Error synthesizing speech');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Use SSML",
                  style: TextStyle(color: Colors.white),
                ),
                Switch(
                  value: _useSSML,
                  onChanged: (value) {
                    setState(() {
                      _useSSML = value;
                    });
                  },
                  activeColor: Colors.amber,
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  "Batch",
                  style: TextStyle(color: Colors.white),
                ),
                Switch(
                  value: _isAsync,
                  onChanged: (value) {
                    setState(() {
                      _isAsync = value;
                    });
                  },
                  activeColor: Colors.amber,
                ),
              ],
            ),
          ],
        ),
        ChildBuilder(
          builder: (_, child) {
            if (!_useSSML) return child;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _useSSML ? 200 : 300),
              child: child,
            );
          },
          child: TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Enter text',
              labelStyle: TextStyle(color: Colors.white.withAlpha(180)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withAlpha(80)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.amber),
              ),
            ),
            maxLines: _useSSML ? null : 5,
          ),
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<bool>(
          valueListenable: _ttsService.isLoadingSpeakers,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return ValueListenableBuilder<List<String>>(
              valueListenable: _ttsService.speakers,
              builder: (context, speakers, child) {
                return ValueListenableBuilder<String?>(
                  valueListenable: _ttsService.selectedSpeaker,
                  builder: (context, selectedSpeaker, child) {
                    if (speakers.isEmpty) {
                      return const Text(
                        'Could not load speakers. Is the server running?',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    return CustomDropdown<String>.search(
                      hintText: 'Select Speaker',
                      items: speakers,
                      initialItem: selectedSpeaker,
                      onChanged: (value) {
                        _ttsService.selectedSpeaker.value = value;
                      },
                      decoration: CustomDropdownDecoration(
                        headerStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        listItemStyle: const TextStyle(color: Colors.white),
                        closedFillColor: const Color(0xFF1E1E1E),
                        expandedFillColor: const Color(0xFF222222),
                        closedBorder: Border.all(
                          color: Colors.white.withAlpha(80),
                        ),
                        expandedBorder: Border.all(
                          color: Colors.amber,
                        ),
                        closedBorderRadius: BorderRadius.circular(8),
                        expandedBorderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Column(
          children: [
            Text(
              'Speed: ${_speed.toStringAsFixed(1)}',
              style: const TextStyle(color: Colors.white),
            ),
            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _speed.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _speed = value;
                });
              },
              activeColor: Colors.amber,
              inactiveColor: Colors.grey,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<bool>(
          valueListenable: _ttsService.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const CircularProgressIndicator();
            }
            return ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_isAsync ? 'Synthesize Asynchronously' : 'Speak'),
            );
          },
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder<List<Job>>(
          valueListenable: _ttsService.jobs,
          builder: (context, jobs, child) {
            if (jobs.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildJobsList(jobs);
          },
        ),
      ],
    );
  }

  Widget _buildJobsList(List<Job> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Batch Jobs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Job ID: ${job.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${job.status}',
                          style: TextStyle(
                            color: job.status == 'complete'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        if (job.status == 'processing' ||
                            job.status == 'pending')
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                      ],
                    ),
                    if (job.status == 'complete' &&
                        job.audioSource != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              job.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () => job.isPlaying
                                ? _ttsService.pauseAudio(job)
                                : _ttsService.playAudio(job),
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.white),
                            onPressed: () => _ttsService.stopAudio(job),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
