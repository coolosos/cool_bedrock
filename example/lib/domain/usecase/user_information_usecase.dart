import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:example_cool_bedrock/domain/entities/user_entity.dart';

export 'package:example_cool_bedrock/domain/entities/user_entity.dart';

/// {@template example_cool_bedrock.usecase}
/// Traditional implementation using standard Clean Architecture patterns.
///
/// ✅ WHEN TO USE:
/// - Good for extremely simple logic with minimal error states.
/// - Useful if you want zero dependencies on external utility packages.
///
/// ❌ DOWNSIDES:
/// - High boilerplate: You have to manually write try-catch blocks in every UseCase.
/// - Hard to maintain: Logic for mapping errors, handling nulls, and catching
///   exceptions is mixed with the business logic.
/// - Error-prone: It is easy to forget to catch a specific exception, leading
///   to unhandled crashes.
/// {@endtemplate}
abstract base class UserInformationUsecase
    extends UseCase<UserEntity, AuthParams, FetchUserFailure> {
  /// {@macro example_cool_bedrock.usecase}
  const UserInformationUsecase();
}

/// {@template example_cool_bedrock.usecaseHandler}
/// Optimized implementation
///
/// ✅ BENEFITS:
/// - Separation of Concerns: Obtaining data, transforming it, and handling
///   errors are separated into distinct, clean methods.
/// - Automatic Error Handling: The `Resolver` ($) and `wrapError` manage
///   exceptions automatically, reducing the risk of crashes.
/// - Readability: The business flow is declarative and much easier to
///   review or unit test.
///
/// ❌ DOWNSIDES:
/// - Learning Curve: Developers need to understand the `Resolver` ($) pattern
///   and the specific lifecycle of the Handler methods.
/// - Verbosity in Simple Cases: For very basic logic, this structure might
///   feel like "over-engineering" compared to a simple function.
/// - Rigidity: You must follow the predefined flow (Obtain -> Transform),
///   which might require adaptation for highly unconventional logic.
/// {@endtemplate}
abstract base class UserInformationUsecaseHandler<Remote extends Object>
    extends UseCaseHandler<UserEntity, AuthParams, FetchUserFailure, Remote> {
  /// {@macro example_cool_bedrock.usecaseHandler}
  const UserInformationUsecaseHandler();
}

final class AuthParams extends Params {
  const AuthParams({required this.userId});

  final String userId;

  @override
  bool get isValid => userId.isNotEmpty;

  @override
  List<Object?> get props => [
        userId,
      ];
}

sealed class FetchUserFailure extends Failure {
  const FetchUserFailure({required super.message});
}

final class InvalidUserFailure extends FetchUserFailure {
  const InvalidUserFailure() : super(message: 'Invalid User ID provided.');

  @override
  List<Object?> get props => [message];
}

final class InvalidParamsUserFailure extends FetchUserFailure {
  const InvalidParamsUserFailure()
      : super(message: 'Invalid parameters provided.');
  @override
  List<Object?> get props => [message];
}
