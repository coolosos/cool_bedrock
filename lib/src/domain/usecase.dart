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
/// * [TYPE]: The success type, which must be a domain [Entity].
/// * [UsecaseParams]: The required input parameters, extending [Params].
/// * [LEFT]: The specific type of [Failure] returned on the left side of the Either.
///
/// ### ✅ Benefits:
/// - **Predictability**: Guarantees that errors are handled as data (Left) rather
///   than unhandled exceptions, leading to more stable applications.
/// - **Clean Architecture Compliant**: Forces a clear separation between the
///   caller (UI/Bloc) and the business logic.
/// - **Built-in Validation**: Automatically checks [params.isNotValid] before
///   execution, preventing logic errors from bad input.
///
/// ### ❌ Downsides:
/// - **Manual Error Mapping**: In this base version, you must manually catch
///   exceptions and map them to [LEFT] failures inside the [execute] method.
/// - **Verbosity**: Requires more boilerplate than a simple function, as you
///   need to define Failure types and Params for every action.
///
/// {@endtemplate}
abstract class UseCase<TYPE extends Entity, UsecaseParams extends Params,
    LEFT extends Failure> extends Case<UsecaseParams> {
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
/// This handler enforces a structured lifecycle: **Obtain -> Transform -> Handle Errors**.
///
/// **Type Parameters:**
/// * [TYPE]: The final Domain Entity returned on success.
/// * [UsecaseParams]: The input parameters for this use case.
/// * [LEFT]: The specific Failure type for this domain.
/// * [VALUES]: The intermediary, raw data structure obtained from external sources.
///
/// ### ✅ Benefits:
/// - **Clean Logic Separation**: Decouples data fetching from domain transformation.
/// - **Standardized Flow**: Ensures all UseCases follow the same execution pattern,
///   making code reviews easier.
/// - **Safe Error Propagation**: Uses the [Resolver] pattern to flatten nested
///   error handling (eliminating "callback hell" or deep try-catch blocks).
///
/// ### ❌ Downsides:
/// - **Boilerplate for Simple Tasks**: Might feel verbose for operations that
///   only perform a single repository call with no transformation.
/// - **Stricter Structure**: Forces a specific execution flow which might require
///   adaptation for non-linear business logic.
///
/// {@endtemplate}
abstract class UseCaseHandler<TYPE extends Entity, UsecaseParams extends Params,
        LEFT extends Failure, VALUES extends Object>
    extends UseCase<TYPE, UsecaseParams, LEFT> with UsecaseFlowManager {
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
/// or absence of a value (Some vs None).
///
/// **Type Parameters:**
/// * [TYPE]: The domain [Entity] to be returned if found.
/// * [UsecaseParams]: The input parameters for the query.
///
/// ### ✅ Benefits:
/// - **Null Safety**: Eliminates the risk of `null` related crashes by forcing the
///   caller to handle the [None] case explicitly.
/// - **Semantic Clarity**: Perfect for "Lookup" operations where a missing
///   result is a valid business outcome, not an error (e.g., Search).
/// - **Simplicity**: No need to define complex Failure hierarchies or error
///   mapping logic.
///
/// ### ❌ Downsides:
/// - **Silent Failures**: Since it doesn't return a [Failure], you cannot
///   tell *why* an operation returned [None] (e.g., was it a 404, a timeout, or a server error?).
/// - **Limited Context**: Not suitable for operations where the UI needs to
///   show a specific error message to the user based on what went wrong.
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
/// A specialized Usecase designed to produce an optional [Failure] result,
/// but **no** successful domain [Entity].
///
/// It implements the **Option** functional pattern where:
/// - [None]: Represents **Success** (no failure occurred).
/// - [Some(Failure)]: Represents a **Problem** found during the check.
///
/// ### ✅ Benefits:
/// - **Focused Purpose**: Ideal for standalone validation logic, permission
///   checks, or "guard clauses" that don't need to return data.
/// - **UI Integration**: Very easy to use in form validation where you only
///   care if there is an error message to display.
/// - **Lightweight**: Avoids the overhead of defining a "Success" entity when
///   the only goal is to verify a condition.
///
/// ### ❌ Downsides:
/// - **Inverted Intuition**: Confusing that `None` means "everything is okay."
/// - **Limited Flow**: Cannot pass data forward. If you need to validate *and then*
///   use the validated data, a standard `UseCase` or `UseCaseHandler` is better.
///
/// **Best for:** Validation or verification Usecase (e.g., "Check if Username
/// is Taken" or "Verify Premium Subscription Status").
///
/// **Type Parameter:**
/// * [TYPE]: The specific type of [Failure] returned if the condition fails.
/// {@endtemplate}
abstract class OneWayFailureUseCase<TYPE extends Failure,
    UsecaseParams extends Params> extends Case<UsecaseParams> {
  /// {@macro cool_way_failure_usecase}
  const OneWayFailureUseCase();

  /// Executes the logic and returns an [Option] containing the [Failure]
  /// if the condition fails, or [None] if the check passes (success).
  @override
  Future<Option<TYPE>> call(UsecaseParams params);
}
