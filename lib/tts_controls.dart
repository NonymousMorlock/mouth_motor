import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;

class Job {
  final String id;
  String status;
  String? audioUrl;
  AudioSource? audioSource;
  SoundHandle? handle;
  bool isPlaying = false;

  Job({required this.id, this.status = 'pending', this.audioUrl});
}

class TtsControls extends StatefulWidget {
  const TtsControls({super.key});

  @override
  State<TtsControls> createState() => _TtsControlsState();
}

class _TtsControlsState extends State<TtsControls> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Job> _jobs = [];
  Timer? _pollingTimer;
  final soloud = SoLoud.instance;

  bool _isLoading = false;
  bool _isLoadingSpeakers = true;
  List<String> _speakers = [];
  String? _selectedSpeaker;
  double _speed = 1.0;
  bool _useSSML = false;
  bool _isAsync = false;

  @override
  void initState() {
    super.initState();
    _fetchSpeakers();
    _startPolling();
    soloud.setVisualizationEnabled(true);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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

  Future<void> _loadAudio(Job job) async {
    if (job.audioUrl == null) return;
    try {
      final source = await soloud.loadUrl(job.audioUrl!);
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

  Future<void> _synthesizeAsync() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isAsync) {
      await _synthesizeAsync();
    } else {
      await _speak();
    }
  }

  Future<void> _speak() async {
    if (_controller.text.isEmpty || _selectedSpeaker == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5002/api/synthesize'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': _controller.text,
          'speaker': _selectedSpeaker,
          'speed': _speed,
          'ssml': _useSSML,
        }),
      );

      if (response.statusCode == 200) {
        Uint8List audioData = response.bodyBytes;
        await _audioPlayer.play(BytesSource(audioData));
      } else {
        _showError('Error synthesizing speech: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Error connecting to the server: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _fetchSpeakers() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5002/api/speakers'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> speakerList = json.decode(response.body);
        if (mounted) {
          setState(() {
            _speakers = speakerList.map((s) => s.toString()).toList();
            if (_speakers.isNotEmpty) {
              _selectedSpeaker = _speakers[0];
            }
          });
        }
      } else {
        _showError('Failed to fetch speakers: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showError('Error connecting to server: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSpeakers = false;
        });
      }
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
        TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Enter text',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.amber),
            ),
          ),
          maxLines: _useSSML ? null : 5,
        ),
        const SizedBox(height: 20),
        if (_isLoadingSpeakers)
          const Center(child: CircularProgressIndicator())
        else if (_speakers.isNotEmpty)
          CustomDropdown<String>.search(
            hintText: 'Select Speaker',
            items: _speakers,
            initialItem: _selectedSpeaker,
            onChanged: (value) {
              setState(() {
                _selectedSpeaker = value;
              });
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
              expandedBorder: Border.all(
                color: Colors.amber,
              ),
              closedBorderRadius: BorderRadius.circular(8),
              expandedBorderRadius: BorderRadius.circular(8),
            ),
          )
        else
          const Text(
            'Could not load speakers. Is the server running?',
            style: TextStyle(color: Colors.red),
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
        if (_isLoading)
          const CircularProgressIndicator()
        else
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_isAsync ? 'Synthesize Asynchronously' : 'Speak'),
          ),
        const SizedBox(height: 20),
        if (_jobs.isNotEmpty) _buildJobsList(),
      ],
    );
  }

  Widget _buildJobsList() {
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
          itemCount: _jobs.length,
          itemBuilder: (context, index) {
            final job = _jobs[index];
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
                                ? _pauseAudio(job)
                                : _playAudio(job),
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.white),
                            onPressed: () => _stopAudio(job),
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
