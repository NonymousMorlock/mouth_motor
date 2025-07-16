import 'package:dartz/dartz.dart';
import 'package:motor_mouth/core/errors/exception.dart';
import 'package:motor_mouth/core/errors/failure.dart';
import 'package:motor_mouth/core/utils/typedefs.dart';

class RepoImplGuard {
  const RepoImplGuard();

  ResultFuture<T> call<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (exception) {
      return Left(ServerFailure.fromException(exception));
    }
  }
}
