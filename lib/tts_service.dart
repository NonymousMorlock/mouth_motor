import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_soloud/flutter_soloud.dart';

class Job {
  final String id;
  String status;
  String? audioUrl;
  AudioSource? audioSource;
  SoundHandle? handle;
  bool isPlaying = false;

  Job({required this.id, this.status = 'pending', this.audioUrl});

  // copywith
  Job copyWith({
    String? id,
    String? status,
    String? audioUrl,
    AudioSource? audioSource,
    SoundHandle? handle,
    bool? isPlaying,
  }) {
    return Job(
      id: id ?? this.id,
      status: status ?? this.status,
      audioUrl: audioUrl ?? this.audioUrl,
    )
      ..audioSource = audioSource ?? this.audioSource
      ..handle = handle ?? this.handle
      ..isPlaying = isPlaying ?? this.isPlaying;
  }
}

class TtsService {
  TtsService._();
  static final instance = TtsService._();

  final ValueNotifier<List<Job>> jobs = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<String>> speakers = ValueNotifier([]);
  final ValueNotifier<String?> selectedSpeaker = ValueNotifier(null);
  final ValueNotifier<bool> isLoadingSpeakers = ValueNotifier(true);

  Timer? _pollingTimer;
  final soloud = SoLoud.instance;

  void dispose() {
    _pollingTimer?.cancel();
    jobs.dispose();
    isLoading.dispose();
    speakers.dispose();
    selectedSpeaker.dispose();
    isLoadingSpeakers.dispose();
  }

  void startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkAllJobsStatus();
    });
  }

  Future<void> _checkAllJobsStatus() async {
    for (var job in jobs.value) {
      if (job.status == 'pending' || job.status == 'processing') {
        await _checkJobStatus(job);
      }
    }
  }

  Future<void> _checkJobStatus(Job job) async {
    try {
      final result = await compute(
        _checkStatusRequest,
        job.id,
      );
      final currentJobs = List<Job>.from(jobs.value);
      final index = currentJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        final existingJob = currentJobs[index];
        currentJobs[index] = existingJob.copyWith(
          status: result['status'],
          audioUrl: result['status'] == 'complete'
              ? 'http://localhost:5002${result['url']}'
              : existingJob.audioUrl,
        );

        if (result['status'] == 'complete') {
          await _loadAudio(currentJobs[index]);
        }
        jobs.value = currentJobs;
      }
    } catch (e) {
      print('Error checking status for job ${job.id}: $e');
    }
  }

  Future<void> _loadAudio(Job job) async {
    if (job.audioUrl == null) return;
    try {
      final source = await soloud.loadUrl(job.audioUrl!);
      final currentJobs = List<Job>.from(jobs.value);
      final index = currentJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        currentJobs[index] = job.copyWith(audioSource: source);
        jobs.value = currentJobs;
      }
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  Future<void> playAudio(Job job) async {
    if (job.audioSource == null) return;
    SoundHandle handle;
    if (job.handle != null) {
      final paused = soloud.getPause(job.handle!);
      if (paused) {
        soloud.setPause(job.handle!, false);
      }
      handle = job.handle!;
    } else {
      handle = await soloud.play(job.audioSource!);
    }

    final currentJobs = List<Job>.from(jobs.value);
    final index = currentJobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      currentJobs[index] = job.copyWith(handle: handle, isPlaying: true);
      jobs.value = currentJobs;
    }
  }

  void pauseAudio(Job job) {
    if (job.handle != null) {
      soloud.setPause(job.handle!, true);
      final currentJobs = List<Job>.from(jobs.value);
      final index = currentJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        currentJobs[index] = job.copyWith(isPlaying: false);
        jobs.value = currentJobs;
      }
    }
  }

  void stopAudio(Job job) {
    if (job.handle != null) {
      soloud.stop(job.handle!);
      final currentJobs = List<Job>.from(jobs.value);
      final index = currentJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        currentJobs[index] = job.copyWith(handle: null, isPlaying: false);
        jobs.value = currentJobs;
      }
    }
  }

  Future<void> synthesizeAsync({
    required String text,
    required String? speaker,
    required double speed,
    required bool ssml,
  }) async {
    isLoading.value = true;
    try {
      final result = await compute(
        _synthesizeAsyncRequest,
        {
          'text': text,
          'speaker': speaker,
          'speed': speed,
          'ssml': ssml,
        },
      );
      if (result != null) {
        final currentJobs = List<Job>.from(jobs.value);
        currentJobs.insert(0, Job(id: result['job_id']));
        jobs.value = currentJobs;
      }
    } catch (e) {
      print('Error connecting to server: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Uint8List?> synthesizeSync({
    required String text,
    required String? speaker,
    required double speed,
    required bool ssml,
  }) async {
    isLoading.value = true;
    try {
      return await compute(
        _synthesizeSyncRequest,
        {
          'text': text,
          'speaker': speaker,
          'speed': speed,
          'ssml': ssml,
        },
      );
    } catch (e) {
      print('Error connecting to server: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSpeakers() async {
    isLoadingSpeakers.value = true;
    try {
      final speakerList = await compute(_fetchSpeakersRequest, null);
      speakers.value = speakerList;
      if (speakerList.isNotEmpty) {
        selectedSpeaker.value = speakerList[0];
      }
    } catch (e) {
      print('Error connecting to server: $e');
    } finally {
      isLoadingSpeakers.value = false;
    }
  }
}

Future<Map<String, dynamic>> _checkStatusRequest(String jobId) async {
  final response = await http.get(
    Uri.parse('http://localhost:5002/api/status/$jobId'),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to check status');
  }
}

Future<Map<String, dynamic>?> _synthesizeAsyncRequest(
    Map<String, dynamic> params) async {
  final response = await http.post(
    Uri.parse('http://localhost:5002/api/synthesize-async'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(params),
  );
  if (response.statusCode == 202 || response.statusCode == 200) {
    return json.decode(response.body);
  }
  return null;
}

Future<Uint8List?> _synthesizeSyncRequest(Map<String, dynamic> params) async {
  final response = await http.post(
    Uri.parse('http://localhost:5002/api/synthesize'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(params),
  );
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  return null;
}

Future<List<String>> _fetchSpeakersRequest(dynamic _) async {
  final response = await http.get(
    Uri.parse('http://localhost:5002/api/speakers'),
  );
  if (response.statusCode == 200) {
    final List<dynamic> speakerList = json.decode(response.body);
    return speakerList.map((s) => s.toString()).toList();
  } else {
    throw Exception('Failed to fetch speakers');
  }
}
