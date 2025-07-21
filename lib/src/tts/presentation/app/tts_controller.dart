import 'dart:collection';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:motor_mouth/core/common/models/job.dart';

class TTSController {
  TTSController({required SoLoud soLoud}) : _soLoud = soLoud;

  final SoLoud _soLoud;
  List<Job> _jobs = [];

  UnmodifiableListView<Job> get jobs => UnmodifiableListView(_jobs);

  final List<String> speakers = [];
  String? _selectedSpeaker;

  String? get selectedSpeaker => _selectedSpeaker;

  void setSelectedSpeaker(String? speaker) {
    if (_selectedSpeaker != speaker) _selectedSpeaker = speaker;
  }

  // I do not want to make this a setter because this is a controller and I
  // do not want to expose the internal state directly.
  // ignore: use_setters_to_change_properties
  void setJobs(List<Job> jobs) {
    _jobs = jobs;
  }

  Future<void> playAudio(Job job) async {
    if (job.audioSource == null) return;
    SoundHandle handle;
    if (job.handle != null) {
      final paused = _soLoud.getPause(job.handle!);
      if (paused) {
        _soLoud.setPause(job.handle!, false);
      }
      handle = job.handle!;
    } else {
      handle = await _soLoud.play(job.audioSource!);
    }

    final currentJobs = List<Job>.from(_jobs);
    final index = currentJobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      currentJobs[index] = job.copyWith(handle: handle, isPlaying: true);
      setJobs(currentJobs);
    }
  }

  void pauseAudio(Job job) {
    if (job.handle != null) {
      _soLoud.setPause(job.handle!, true);
      final currentJobs = List<Job>.from(_jobs);
      final index = currentJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        currentJobs[index] = job.copyWith(isPlaying: false);
        setJobs(currentJobs);
      }
    }
  }

  Future<void> loadAudio(Job job) async {
    if (job.audioUrl == null) return;
    final source = await _soLoud.loadUrl(job.audioUrl!);
    final currentJobs = List<Job>.from(jobs);
    final index = currentJobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      currentJobs[index] = job.copyWith(audioSource: source);
      setJobs(currentJobs);
    }
  }

  Future<void> stopAudio(Job job) async {
    if (job.handle != null) {
      await _soLoud.stop(job.handle!);
      final currentJobs = List<Job>.from(_jobs);
      final index = currentJobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        currentJobs[index] = job.copyWith(
          setHandleNull: true,
          isPlaying: false,
        );
        setJobs(currentJobs);
      }
    }
  }
}
