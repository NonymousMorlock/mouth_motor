import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/src/tts/domain/params/synthesis_params.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';
import 'package:motor_mouth/src/tts/domain/usecases/synthesize_sync.dart';

import 'tts_repo.mock.dart';

void main() {
  late TTSRepo repo;
  late SynthesizeSync usecase;

  setUp(() {
    repo = MockTTSRepo();
    usecase = SynthesizeSync(repo);
  });

  test('Should call [TTSRepo.synthesizeSync]', () async {
    const tParams = SynthesisParams.empty();
    final tResponse = Uint8List(0);

    when(
      () => repo.synthesizeSync(
        text: any(named: 'text'),
        speaker: any(named: 'speaker'),
        speed: any(named: 'speed'),
        ssml: any(named: 'ssml'),
      ),
    ).thenAnswer((_) async => Right(tResponse));

    final result = await usecase(tParams);

    expect(result, equals(Right<Failure, Uint8List>(tResponse)));

    verify(
      () => repo.synthesizeSync(
        text: tParams.text,
        speaker: tParams.speaker,
        speed: tParams.speed,
        ssml: tParams.ssml,
      ),
    ).called(1);
    verifyNoMoreInteractions(repo);
  });
}
