import 'package:equatable/equatable.dart';
import 'package:motor_mouth/core/errors/exception.dart';

abstract interface class Failure extends Equatable {
  const Failure({required this.message, required this.title});

  final String message;
  final String title;

  @override
  List<Object> get props => [message, title];
}

interface class ServerFailure extends Failure {
  const ServerFailure({required super.message, required super.title});

  ServerFailure.fromException(ServerException exception)
    : this(message: exception.message, title: exception.title);

  @override
  String toString() => 'ServerFailure: $message';
}
