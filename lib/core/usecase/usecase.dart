// Usecase needs to be abstract so that it can be implemented by other classes.
// ignore_for_file: one_member_abstracts

import 'package:motor_mouth/core/utils/typedefs.dart';

/// An abstract interface for use cases that require parameters.
///
/// This class is designed to be implemented by other classes to define specific
/// use case logic. It enforces the implementation of a `call` method that takes
/// parameters.
///
/// Type parameters:
/// - `Type`: The type of the result returned by the use case.
/// - `Params`: The type of the parameters required by the use case.
abstract interface class UsecaseWithParams<Type, Params> {
  /// Default constructor for the `UsecaseWithParams` class.
  const UsecaseWithParams();

  /// Executes the use case with the provided parameters.
  ///
  /// Parameters:
  /// - `params`: The input parameters required to execute the use case.
  ///
  /// Returns:
  /// A `ResultFuture` containing the result of the use case execution.
  ResultFuture<Type> call(Params params);
}

/// An abstract interface for use cases that do not require parameters.
///
/// This class is designed to be implemented by other classes to define specific
/// use case logic. It enforces the implementation of a `call` method without
/// requiring any parameters.
///
/// Type parameters:
/// - `Type`: The type of the result returned by the use case.
abstract interface class UsecaseWithoutParams<Type> {
  /// Default constructor for the `UsecaseWithoutParams` class.
  const UsecaseWithoutParams();

  /// Executes the use case without requiring any parameters.
  ///
  /// Returns:
  /// A `ResultFuture` containing the result of the use case execution.
  ResultFuture<Type> call();
}
