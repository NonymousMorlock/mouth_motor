import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';
import 'package:motor_mouth/src/tts/domain/usecases/fetch_audio.dart';

import 'tts_repo.mock.dart';

void main() {
  late TTSRepo repo;
  late FetchAudio usecase;

  setUp(() {
    repo = MockTTSRepo();
    usecase = FetchAudio(repo);
  });

  test('Should call [TTSRepo.fetchAudio]', () async {
    const tJobId = '12345';
    final tResponse = Uint8List(1);
    when(
      () => repo.fetchAudio(tJobId),
    ).thenAnswer((_) async => Right(tResponse));

    final result = await usecase(tJobId);

    expect(result, Right<Failure, Uint8List>(tResponse));

    verify(() => repo.fetchAudio(tJobId));
    verifyNoMoreInteractions(repo);
  });
}
