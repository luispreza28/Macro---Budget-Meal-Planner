import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  const Failure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message});
}

/// Planning algorithm failures
class PlanningFailure extends Failure {
  const PlanningFailure({required super.message});
}

/// Network-related failures (for future external API integration)
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Validation failures for user input
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Subscription and billing failures
class BillingFailure extends Failure {
  const BillingFailure({required super.message});
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message});
}
