import 'package:motor_mouth/core/usecase/usecase.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/params/synthesis_params.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';

class SynthesizeAsync
    implements UsecaseWithParams<SynthesizeAsyncResponse, SynthesisParams> {
  const SynthesizeAsync(this._repo);

  final TTSRepo _repo;

  @override
  ResultFuture<SynthesizeAsyncResponse> call(SynthesisParams params) {
    return _repo.synthesizeAsync(
      text: params.text,
      speaker: params.speaker,
      speed: params.speed,
      ssml: params.ssml,
    );
  }
}
