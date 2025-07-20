import 'package:equatable/equatable.dart';

final class SynthesisParams extends Equatable {
  const SynthesisParams({
    required this.text,
    this.speaker,
    this.speed,
    this.ssml,
  });

  const SynthesisParams.empty() : this(text: 'Test String');

  final String text;
  final String? speaker;
  final double? speed;
  final bool? ssml;

  @override
  List<Object?> get props => [text, speaker, speed, ssml];
}
