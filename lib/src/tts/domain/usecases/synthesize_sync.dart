import 'dart:typed_data';

import 'package:motor_mouth/core/usecase/usecase.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/params/synthesis_params.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';

class SynthesizeSync implements UsecaseWithParams<Uint8List?, SynthesisParams> {
  const SynthesizeSync(this._repo);

  final TTSRepo _repo;

  @override
  ResultFuture<Uint8List?> call(SynthesisParams params) {
    return _repo.synthesizeSync(
      text: params.text,
      speaker: params.speaker,
      speed: params.speed,
      ssml: params.ssml,
    );
  }
}
