import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:tts_app/async_tts_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoLoud.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local TTS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TtsPage(),
    AsyncTtsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.speaker_phone),
            label: 'Real-time',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Batch'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class TtsPage extends StatefulWidget {
  const TtsPage({super.key});

  @override
  State<TtsPage> createState() => _TtsPageState();
}

class _TtsPageState extends State<TtsPage> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  List<String> _speakers = [];
  String? _selectedSpeaker;
  double _speed = 1.0;
  bool _useSSML = false;

  @override
  void initState() {
    super.initState();
    _fetchSpeakers();
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
    print(message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time TTS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
              decoration: const InputDecoration(
                labelText: 'Enter text or SSML',
              ),
              maxLines: _useSSML ? null : 1,
            ),
            const SizedBox(height: 20),
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
              )
            else
              const Text("Fetching speakers..."),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(onPressed: _speak, child: const Text('Speak')),
          ],
        ),
      ),
    );
  }
}
