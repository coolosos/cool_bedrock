import 'dart:async';

import 'package:cool_bedrock/src/domain/usecase_flow_manager.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

import '../errors/issue.dart';
import 'entity.dart';
import 'params.dart';

export 'package:cool_bedrock/src/domain/usecase_flow_manager.dart'
    show Resolver;

export '../errors/issue.dart' show Failure;
export 'entity.dart';
export 'params.dart';

/// {@template cool_bedrock.case}
/// The sealed base contract for all executable operations, representing a
/// command or query in the application.
///
/// This provides a uniform interface for running logic via the [call] method.
/// {@endtemplate}
sealed class Case<UsecaseParams extends Params> {
  /// {@macro cool_bedrock.case}
  const Case();

  /// Executes the command or query with the provided parameters.
  ///
  /// The return type is typically either a structured result (`Either<L, R>`)
  /// or an optional result (`Option<T>`).
  ///
  /// The return type `Object` is a placeholder; concrete subclasses
  /// must specify the exact functional return type (e.g., `Either`, `Option`).
  Future<Object> call(UsecaseParams params);
}

/// {@template cool_bedrock.usecase}
/// The primary contract for a Usecase that produces a predictable result or a typed error.
///
/// It implements the **Either** functional pattern: it returns either a [LEFT] failure
/// upon error, or a successful [TYPE] entity upon success.
///
/// **Type Parameters:**
/// * **TYPE**: The success type, which must be a domain [Entity].
/// * **UsecaseParams**: The required input parameters, extending [Params].
/// * **LEFT**: The specific type of [Failure] returned on the left side of the Either.
/// {@endtemplate}
abstract class UseCase<
  TYPE extends Entity,
  UsecaseParams extends Params,
  LEFT extends Failure
>
    extends Case<UsecaseParams> {
  /// {@macro cool_bedrock.usecase}
  const UseCase();

  /// Defines the specific [Failure] that should be returned when the
  /// input [UsecaseParams] are invalid.
  LEFT onInvalidParams();

  /// Entry point for the Usecase execution.
  ///
  /// It validates the [params] before delegating the execution to the [execute] method.
  /// If validation fails, it immediately returns the [Failure] defined by [onInvalidParams].
  @override
  Future<Either<LEFT, TYPE>> call(UsecaseParams params) async {
    if (params.isNotValid) {
      return Left(onInvalidParams());
    }

    return execute(params);
  }

  /// The core logic execution method.
  ///
  /// Concrete classes must implement this to perform the domain logic.
  @protected
  Future<Either<LEFT, TYPE>> execute(UsecaseParams params);
}

/// {@template cool_bedrock.usecase_handler}
/// A specialized Usecase designed to manage the flow of obtaining data ([VALUES]),
/// handling potential errors, and transforming the result into the final [TYPE].
///
/// It mixes in [UsecaseFlowManager] (likely a helper mixin for chaining futures
/// and handling the `Either` monad).
///
/// **Type Parameters:**
/// * **VALUES**: The intermediary, raw data structure obtained from external sources.
/// {@endtemplate}
abstract class UseCaseHandler<
  TYPE extends Entity,
  UsecaseParams extends Params,
  LEFT extends Failure,
  VALUES extends Object
>
    extends UseCase<TYPE, UsecaseParams, LEFT>
    with UsecaseFlowManager {
  /// {@macro cool_bedrock.usecase_handler}
  const UseCaseHandler();

  /// Retrieves the necessary data or dependencies to perform the use case logic.
  ///
  /// This method uses the [Resolver] (denoted by `$`) to safely unwrap values
  /// from other fallible operations (e.g., other Usecase or Services)
  /// while automatically propagating errors.
  FutureOr<VALUES> obtainValues(Resolver<LEFT> $, UsecaseParams params);

  /// Transforms the raw intermediary data ([VALUES]) into the final domain [TYPE].
  ///
  /// This step is purely deterministic transformation logic, assuming [VALUES]
  /// were successfully obtained.
  FutureOr<TYPE> transformation(VALUES values);

  /// Delegates the execution flow to the specialized handler provided by the mixin.
  ///
  /// This method orchestrates the calling of [obtainValues] and [transformation]
  /// and manages the [Either] wrapping and error propagation logic.
  @override
  Future<Either<LEFT, TYPE>> execute(UsecaseParams params) {
    return handler<VALUES>(
      getValues: ($) => obtainValues($, params),
      transform: transformation,
      wrapError: wrapError,
    ).run();
  }
}

/// {@template cool_bedrock.one_way_usecase}
/// A Usecase that either returns a domain [Entity] or nothing at all,
/// but is **not** expected to fail with a specific [Failure].
///
/// It implements the **Option** functional pattern, signaling the success
/// or absence of a value.
///
/// **Best for:** Queries where the expected result might simply be missing
/// (e.g., "Find User by ID" which may return None instead of a Failure).
/// {@endtemplate}
abstract class OneWayUseCase<TYPE extends Entity, UsecaseParams extends Params>
    extends Case<UsecaseParams> {
  /// {@macro cool_bedrock.one_way_usecase}
  const OneWayUseCase();

  /// Executes the logic and returns an [Option] containing the [TYPE]
  /// if successful and found, or [None] if the value is absent.
  @override
  Future<Option<TYPE>> call(UsecaseParams params);
}

/// {@template cool_bedrock.one_way_failure_usecase}
/// A specialized Usecase designed to produce an optional [Failure] result
/// or nothing, but **no** successful domain [Entity].
///
/// This is sometimes used for validation or verification Usecase that check
/// a condition and return a Failure only if the condition is not met.
///
/// **Type Parameter:**
/// * **TYPE**: The specific type of [Failure] returned if the condition fails.
/// {@endtemplate}
abstract class OneWayFailureUseCase<
  TYPE extends Failure,
  UsecaseParams extends Params
>
    extends Case<UsecaseParams> {
  /// {@macro cool_way_failure_usecase}
  const OneWayFailureUseCase();

  /// Executes the logic and returns an [Option] containing the [Failure]
  /// if the condition fails, or [None] if the check passes (success).
  @override
  Future<Option<TYPE>> call(UsecaseParams params);
}
