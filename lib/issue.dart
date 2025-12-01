@pragma('vm:entry-point')
library;

import 'package:equatable/equatable.dart';

/// {@template cool_bedrock.issue}
/// The sealed base class for all application errors, faults, and warnings.
///
/// An [Issue] is a structural way to represent a problem that occurred
/// within any layer of the application (Domain, Repository, or Data Source).
///
/// All possible error types are restricted to the types defined within
/// the same package/library, enabling robust pattern matching.
/// {@endtemplate}
// coverage:ignore-start
sealed class Issue extends Equatable {
  const Issue({this.message});

  /// A human-readable message describing the issue or the cause of the error.
  final String? message;
  @override
  bool? get stringify => true;
}

//! usecase
/// {@template cool_bedrock.failure}
/// Represents an expected error result from the Domain or Usecase layer.
///
/// Failures are typically the result of **business logic violations**
/// (e.g., "User not authorized," "Insufficient stock," "Invalid input")
/// or the final, high-level interpretation of a lower-level error
/// (e.g., mapping a `DataSourceException` to a `ServerUnavailableFailure`).
/// {@endtemplate}
abstract base class Failure extends Issue {
  /// {@macro cool_bedrock.failure}
  const Failure({super.message});
}

/// {@template cool_bedrock.repository_error}
/// Represents an error that occurred within the Repository layer.
///
/// These errors signify problems during data retrieval, caching, or data source
/// orchestration, but are not necessarily tied to a specific network request.
/// They often map lower-level [DataSourceException]s into a more abstract
/// repository context (e.g., "Database connection failed," "Cache expired").
/// {@endtemplate}
abstract base class RepositoryError extends Issue {
  /// {@macro cool_bedrock.repository_error}
  const RepositoryError({super.message});
}

/// {@template cool_bedrock.data_source_exception}
/// Represents a low-level exception thrown by the Data Source layer
/// (e.g., HTTP client, local storage, or API wrapper).
///
/// These errors contain technical details necessary for debugging and mapping
/// to higher-level [RepositoryError] or [Failure] types.
/// {@endtemplate}
abstract base class DataSourceException extends Issue implements Exception {
  /// {@macro cool_bedrock.data_source_exception}
  const DataSourceException({
    this.requestHeaders,
    this.requestUri,
    this.requestBody,
    super.message,
  });

  /// The HTTP headers used in the failed request.
  final Map<String, String>? requestHeaders;

  /// The URI targeted by the failed request
  final Uri? requestUri;

  /// The body of the request that caused the exception (e.g., for logging)
  final Object? requestBody;
  @override
  List<Object?> get props => [requestHeaders, requestUri, requestBody];
}
// coverage:ignore-end

/// {@template cool_bedrock.usecase_exception}
/// An explicit exception type wrapper used to propagate a specific [Failure]
/// instance outside of a Usecase execution.
///
/// This is used when a Usecase cannot return the expected result (T) and must
/// interrupt the flow by throwing a typed exception containing the [Failure].
///
/// **Type Parameter:**
/// * **Promotional**: Ensures the thrown exception strictly contains an instance
///   that is a subtype of [Failure].
/// {@endtemplate}
final class UsecaseException<Promotional extends Failure> implements Exception {
  const UsecaseException(this.failure);

  final Promotional failure;
}
