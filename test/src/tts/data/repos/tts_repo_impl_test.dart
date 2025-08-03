import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:motor_mouth/core/errors/exception.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/core/utils/repo_impl_guard.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';
import 'package:motor_mouth/src/tts/data/datasources/tts_remote_data_src.dart';
import 'package:motor_mouth/src/tts/data/repos/tts_repo_impl.dart';

class MockTTSRemoteDataSrc extends Mock implements TTSRemoteDataSrc {}

class MockRepoImplGuard extends Mock implements RepoImplGuard {}

void main() {
  late TTSRepoImpl repoImpl;
  late TTSRemoteDataSrc remoteDataSrc;
  late RepoImplGuard guard;

  setUp(() {
    remoteDataSrc = MockTTSRemoteDataSrc();
    guard = MockRepoImplGuard();
    repoImpl = TTSRepoImpl(remoteDataSrc: remoteDataSrc, guard: guard);
  });

  setUpAll(() {
    // Registering the fallback for the `call` method of RepoImplGuard
    // This is crucial because `call` is a generic method.
    registerFallbackValue(() async => Future<dynamic>.value());
  });

  const tJobId = '12345';

  const tServerException = ServerException(
    message: 'Server Down',
    title: '500',
  );
  final tServerFailure = ServerFailure.fromException(tServerException);

  group('checkStatus', () {
    const tResponse = (
      jobId: tJobId,
      status: 'Test String',
      url: 'Test String',
      error: null,
    );

    test(
      'Should return [Right<JobStatusResponse>] when remote call is successful',
      () async {
        // Stubbing the remoteDataSrc.checkStatus call
        when(
          () => remoteDataSrc.checkStatus(any()),
        ).thenAnswer((_) async => tResponse);

        // Stubbing the guard.call method
        // When guard.call is invoked with any function, it should
        // execute that function and wrap its result in a Right.
        when(
          () => guard.call(any<Future<JobStatusResponse> Function()>()),
        ).thenAnswer((invocation) async {
          // Get the function passed to the guard's call method
          final fn =
              invocation.positionalArguments[0]
                  as Future<JobStatusResponse> Function();
          return Right(await fn());
        });

        final result = await repoImpl.checkStatus(tJobId);

        expect(result, const Right<Failure, JobStatusResponse>(tResponse));

        verify(() => remoteDataSrc.checkStatus(tJobId)).called(1);
        verify(
          () => guard(any<Future<JobStatusResponse> Function()>()),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSrc);
        verifyNoMoreInteractions(guard);
      },
    );

    test(
      'Should return [Left<ServerFailure>] when remote call throws '
      '[ServerException]',
      () async {
        // Stubbing the remoteDataSrc.checkStatus call to throw an exception
        when(
          () => remoteDataSrc.checkStatus(any()),
        ).thenThrow(tServerException);

        // Stubbing the guard.call method for the error case
        when(
          () => guard.call(any<Future<JobStatusResponse> Function()>()),
        ).thenAnswer((invocation) async {
          // Get the function passed to the guard's call method
          final fn =
              invocation.positionalArguments[0]
                  as Future<JobStatusResponse> Function();
          try {
            await fn();
            return const Right(tResponse); // Should not reach here
          } on ServerException catch (exception) {
            return Left(ServerFailure.fromException(exception));
          }
        });

        final result = await repoImpl.checkStatus(tJobId);

        expect(result, Left<Failure, JobStatusResponse>(tServerFailure));

        verify(() => remoteDataSrc.checkStatus(tJobId)).called(1);
        verify(
          () => guard(any<Future<JobStatusResponse> Function()>()),
        ).called(1);

        verifyNoMoreInteractions(remoteDataSrc);
        verifyNoMoreInteractions(guard);
      },
    );
  });
}
