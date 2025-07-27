import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/domain/repos/tts_repo.dart';
import 'package:motor_mouth/src/tts/domain/usecases/check_status.dart';

import 'tts_repo.mock.dart';

void main() {
  late CheckStatus usecase;
  late TTSRepo repo;

  setUp(() {
    repo = MockTTSRepo();
    usecase = CheckStatus(repo);
  });

  test('Should call the [TTSRepo.checkStatus]', () async {
    const tJobId = '12345';
    const tResponse = (
      jobId: tJobId,
      status: 'Test String',
      url: 'Test String',
      error: null,
    );

    when(
      () => repo.checkStatus(any()),
    ).thenAnswer((_) async => const Right(tResponse));

    final result = await usecase(tJobId);

    expect(result, isA<Right<Failure, JobStatusResponse>>());

    verify(() => repo.checkStatus(tJobId)).called(1);
    verifyNoMoreInteractions(repo);
  });
}
