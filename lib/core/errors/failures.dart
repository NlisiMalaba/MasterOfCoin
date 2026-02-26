import 'package:equatable/equatable.dart';

/// Base class for failures in the application.
abstract class Failure extends Equatable {
  const Failure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message]);
}
