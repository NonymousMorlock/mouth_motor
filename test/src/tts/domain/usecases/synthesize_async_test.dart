import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/params/synthesis_params.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';
import 'package:motor_mouth/src/tts/domain/usecases/synthesize_async.dart';

import 'tts_repo.mock.dart';

void main() {
  late TTSRepo repo;
  late SynthesizeAsync usecase;

  setUp(() {
    repo = MockTTSRepo();
    usecase = SynthesizeAsync(repo);
  });

  test('Should call [TTSRepo.synthesizeAsync]', () async {
    const tResponse = (jobId: 'Test String', status: 'Test String');
    const tParams = SynthesisParams.empty();

    when(
      () => repo.synthesizeAsync(
        text: any(named: 'text'),
        speaker: any(named: 'speaker'),
        speed: any(named: 'speed'),
        ssml: any(named: 'ssml'),
      ),
    ).thenAnswer((_) async => const Right(tResponse));

    final result = await usecase(tParams);

    expect(result, isA<Right<Failure, SynthesizeAsyncResponse>>());

    verify(
      () => repo.synthesizeAsync(
        text: tParams.text,
        speaker: tParams.speaker,
        speed: tParams.speed,
        ssml: tParams.ssml,
      ),
    ).called(1);
    verifyNoMoreInteractions(repo);
  });
}
