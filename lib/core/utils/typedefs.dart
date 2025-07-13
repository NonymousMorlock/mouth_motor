import 'package:dartz/dartz.dart';
import 'package:motor_mouth/core/errors/failure.dart';

typedef DataMap = Map<String, dynamic>;
typedef ResultFuture<T> = Future<Either<Failure, T>>;

typedef SynthesizeAsyncResponse = ({String jobId, String status});
typedef JobStatusResponse = ({
  String jobId,
  String status,
  String? url,
  String? error,
});
