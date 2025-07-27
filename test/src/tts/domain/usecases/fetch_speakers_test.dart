import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';
import 'package:motor_mouth/src/tts/domain/usecases/fetch_speakers.dart';

import 'tts_repo.mock.dart';

void main() {
  late FetchSpeakers usecase;
  late TTSRepo repo;

  setUp(() {
    repo = MockTTSRepo();
    usecase = FetchSpeakers(repo);
  });

  test('Should call [TTSRepo.fetchSpeakers]', () async {
    const tResult = ['Test String'];
    when(
      () => repo.fetchSpeakers(),
    ).thenAnswer((_) async => const Right(tResult));

    final result = await usecase();

    expect(result, isA<Right<Failure, List<String>>>());

    verify(() => repo.fetchSpeakers()).called(1);
    verifyNoMoreInteractions(repo);
  });
}
