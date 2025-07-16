import 'package:equatable/equatable.dart';

class ServerException extends Equatable implements Exception {
  const ServerException({required this.message, required this.title});

  final String message;
  final String title;

  @override
  List<Object> get props => [message, title];

  @override
  String toString() => 'ServerException: $message';
}
