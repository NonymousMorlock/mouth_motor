import 'package:equatable/equatable.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class Job extends Equatable {
  const Job({
    required this.id,
    this.status = 'pending',
    this.audioUrl,
    this.audioSource,
    this.handle,
    this.isPlaying = false,
  });

  final String id;
  final String status;
  final String? audioUrl;
  final AudioSource? audioSource;
  final SoundHandle? handle;
  final bool isPlaying;

  Job copyWith({
    String? id,
    String? status,
    String? audioUrl,
    AudioSource? audioSource,
    SoundHandle? handle,
    bool setHandleNull = false,
    bool? isPlaying,
  }) {
    return Job(
      id: id ?? this.id,
      status: status ?? this.status,
      audioUrl: audioUrl ?? this.audioUrl,
      audioSource: audioSource ?? this.audioSource,
      handle: setHandleNull ? null : handle ?? this.handle,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    audioUrl,
    audioSource,
    handle,
    isPlaying,
  ];
}
