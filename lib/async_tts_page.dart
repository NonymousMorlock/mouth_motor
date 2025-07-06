import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;
import 'package:tts_app/audio_visualizer_painter.dart';

class AsyncTtsPage extends StatefulWidget {
  const AsyncTtsPage({super.key});

  @override
  State<AsyncTtsPage> createState() => _AsyncTtsPageState();
}

class Job {
  final String id;
  String status;
  String? audioUrl;
  AudioSource? audioSource;
  SoundHandle? handle;
  bool isPlaying = false;

  Job({required this.id, this.status = 'pending', this.audioUrl});
}

class _AsyncTtsPageState extends State<AsyncTtsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Job> _jobs = [];
  Timer? _pollingTimer;
  late final Ticker ticker;
  late final AudioData audioData;
  Float32List? waveData;

  // Add state for controls
  List<String> _speakers = [];
  String? _selectedSpeaker;
  double _speed = 1.0;
  bool _useSSML = false;
  final soloud = SoLoud.instance;

  @override
  void initState() {
    super.initState();
    soloud.init().then((_) {
      SoLoud.instance.setVisualizationEnabled(true);
    });
    audioData = AudioData(GetSamplesKind.linear);
    ticker = createTicker(_tick);
    ticker.start();
    _fetchSpeakers();
    _startPolling();
  }

  void _tick(Duration elapsed) {
    if (context.mounted) {
      try {
        audioData.updateSamples();
        waveData = audioData.getAudioData();
        setState(() {});
      } on Exception catch (e) {
        debugPrint('$e');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    soloud.deinit();
    ticker.dispose();
    _controller.dispose();
    audioData.dispose();
    super.dispose();
  }

  Future<void> _fetchSpeakers() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5002/api/speakers'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> speakerList = json.decode(response.body);
        setState(() {
          _speakers = speakerList.map((s) => s.toString()).toList();
          if (_speakers.isNotEmpty) {
            _selectedSpeaker = _speakers[0];
          }
        });
      } else {
        _showError('Failed to fetch speakers: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkAllJobsStatus();
    });
  }

  Future<void> _checkAllJobsStatus() async {
    for (var job in _jobs) {
      if (job.status == 'pending' || job.status == 'processing') {
        await _checkJobStatus(job);
      }
    }
  }

  Future<void> _checkJobStatus(Job job) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5002/api/status/${job.id}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            job.status = data['status'];
            if (data['status'] == 'complete') {
              job.audioUrl = 'http://localhost:5002${data['url']}';
              _loadAudio(job);
            }
          });
        }
      }
    } catch (e) {
      print('Error checking status for job ${job.id}: $e');
    }
  }

  Future<void> _synthesizeAsync() async {
    if (_controller.text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5002/api/synthesize-async'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': _controller.text,
          'speaker': _selectedSpeaker,
          'speed': _speed,
          'ssml': _useSSML,
        }),
      );

      if (response.statusCode == 202 || response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _jobs.insert(0, Job(id: data['job_id']));
        });
      } else {
        _showError('Failed to start async job: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    }
  }

  Future<void> _loadAudio(Job job) async {
    if (job.audioUrl == null) return;
    try {
      final source = await soloud.loadUrl(job.audioUrl!);
      await SoLoud.instance.loadWaveform(WaveForm.fSaw, true, 1.0, 0.0);

      setState(() {
        job.audioSource = source;
      });
    } catch (e) {
      print("Error loading audio: $e");
      _showError("Error loading audio: $e");
    }
  }

  Future<void> _playAudio(Job job) async {
    if (job.audioSource == null) return;
    if (job.handle != null) {
      final paused = soloud.getPause(job.handle!);
      if (paused) {
        soloud.setPause(job.handle!, false);
      } else {
        // Already playing or stopped, so restart
        job.handle = await soloud.play(job.audioSource!);
      }
    } else {
      job.handle = await soloud.play(job.audioSource!);
    }
    setState(() {
      job.isPlaying = true;
    });
  }

  void _pauseAudio(Job job) {
    if (job.handle != null) {
      soloud.setPause(job.handle!, true);
      setState(() {
        job.isPlaying = false;
      });
    }
  }

  void _stopAudio(Job job) {
    if (job.handle != null) {
      soloud.stop(job.handle!);
      setState(() {
        job.handle = null;
        job.isPlaying = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async TTS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                const Text("Use SSML"),
                Switch(
                  value: _useSSML,
                  onChanged: (value) {
                    setState(() {
                      _useSSML = value;
                    });
                  },
                ),
              ],
            ),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Enter long text'),
              maxLines: _useSSML ? null : 5,
            ),
            const SizedBox(height: 10),
            if (_speakers.isNotEmpty)
              DropdownButton<String>(
                value: _selectedSpeaker,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSpeaker = newValue;
                  });
                },
                items: _speakers.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                isExpanded: true,
              )
            else
              const Text("Fetching speakers..."),
            const SizedBox(height: 10),
            Text('Speed: ${_speed.toStringAsFixed(1)}'),
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
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _synthesizeAsync,
              child: const Text('Synthesize Asynchronously'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Jobs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: ListView.builder(
                controller: ScrollController(),
                itemCount: _jobs.length,
                itemBuilder: (context, index) {
                  final job = _jobs[index];
                  if (job.status == 'complete' && job.audioSource != null) {
                    return Card(
                      child: AudioPlayerWidget(
                        waveData: waveData ?? Float32List(0),
                        job: job,
                        onPlay: () => _playAudio(job),
                        onPause: () => _pauseAudio(job),
                        onStop: () => _stopAudio(job),
                      ),
                    );
                  } else {
                    return Card(
                      child: ListTile(
                        title: Text('Job ID: ${job.id}'),
                        subtitle: Text('Status: ${job.status}'),
                        trailing: (job.status == 'processing' ||
                                job.status == 'pending')
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                ),
                              )
                            : null,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({
    super.key,
    required this.job,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.waveData,
  });

  final Job job;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onStop;
  final Float32List? waveData;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        setState(() {});
      });

    // To continuously update the waveform, we can drive the animation
    // while the audio is playing.
    if (widget.job.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.job.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.job.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 50,
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              height: 100,
              child: CustomPaint(
                // painter: WaveformPainter(
                //   waveData: widget.waveData?.buffer.asUint8List() ?? Uint8List(0),
                //   color: Theme.of(context).colorScheme.primary,
                // ),
                painter: AudioVisualizerPainter(
                  samples: widget.waveData ?? Float32List(0),
                ),
                child: Container(),
              ),
            ),
          ),
        ),
        Column(
          children: [
            ListTile(
              title: Text('Job ID: ${widget.job.id}'),
              subtitle: Text('Status: ${widget.job.status}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                      widget.job.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed:
                      widget.job.isPlaying ? widget.onPause : widget.onPlay,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: widget.onStop,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.waveData, required this.color});

  final Uint8List waveData;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    if (waveData.isNotEmpty) {
      final barWidth = width / waveData.length;
      for (var i = 0; i < waveData.length; i++) {
        final x = i * barWidth;
        final sample = waveData[i] - 128; // convert to -128 to 127
        final barHeight = (sample.abs() / 128.0) * centerY;

        final rect = Rect.fromLTWH(
          x,
          centerY - barHeight,
          barWidth - 1, // small gap between bars
          barHeight * 2,
        );
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return true; // For simplicity, always repaint.
  }
}
