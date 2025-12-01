import 'dart:async';

import 'package:cool_bedrock/issue.dart';
import 'package:cool_bedrock/usecase.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

typedef Resolver<LEFT> = Future<A> Function<A>(TaskEither<LEFT, A>);

mixin UsecaseFlowManager<
  TYPE extends Entity,
  UsecaseParams extends Params,
  LEFT extends Failure
>
    on UseCase<TYPE, UsecaseParams, LEFT> {
  /// Handles unexpected errors and maps them to a specific [LEFT] failure.
  LEFT wrapError(Object error, StackTrace stackTrace);

  /// Orchestrates the execution flow for error safety.
  ///
  /// * [getValues]: Retrieves raw data or intermediate values using the [Resolver].
  /// * [transform]: Converts the retrieved data into the domain entity [TYPE].
  /// * [onError]: Handles unexpected exceptions and converts them to [LEFT].
  @protected
  TaskEither<LEFT, TYPE> handler<RECORD>({
    required FutureOr<RECORD> Function(Resolver<LEFT> $) getValues,
    required FutureOr<TYPE> Function(RECORD values) transform,
    required LEFT Function(Object error, StackTrace stackTrace) wrapError,
  }) {
    return TaskEither<LEFT, TYPE>.tryCatch(
      () async {
        final data = await TaskEither<LEFT, TYPE>.Do(($) async {
          final data = await getValues($);
          return $(
            mapper(() {
              return transform(data);
            }, wrapError),
          );
        }).run();

        return data.fold((l) => throw UsecaseException<LEFT>(l), (r) => r);
      },
      (error, s) {
        if (error is UsecaseException<LEFT>) {
          return error.failure;
        }
        return wrapError(error, s);
      },
    );
  }

  // Safely executes a data layer operation.
  ///
  /// Wraps a standard `Future<Either>` call. If the operation fails with an [ISSUE],
  /// it allows mapping it to a domain failure [LEFT] via [onLeft].
  ///
  /// If an unexpected exception occurs, [onError] is triggered.
  @protected
  TaskEither<LEFT, VALUE> getValue<VALUE, ISSUE extends Issue>(
    Future<Either<ISSUE, VALUE>> Function() run, {
    LEFT Function(Object error, StackTrace stack)? onError,
    LEFT Function(ISSUE issue)? onLeft,
  }) {
    return TaskEither<LEFT, VALUE>.tryCatch(
      () async {
        final result = await run();
        return result.fold((l) => throw _DataLayerError(l), (r) => r);
      },
      (error, stack) {
        if (error is _DataLayerError<ISSUE>) {
          if (onLeft != null) {
            return onLeft(error.issue);
          }
          return onError?.call(error.issue, stack) ??
              wrapError(error.issue, stack);
        }
        return onError?.call(error, stack) ?? wrapError(error, stack);
      },
    );
  }

  /// Utility to wrap a transformation logic.
  ///
  /// Useful to handle potential exceptions during complex mapping operations.
  @protected
  TaskEither<LEFT, TYPE> mapper(
    FutureOr<TYPE> Function() entitiesMapper,
    LEFT Function(Object error, StackTrace stackTrace)? onError,
  ) {
    return TaskEither<LEFT, TYPE>.tryCatch(
      () async {
        return entitiesMapper();
      },
      (error, s) {
        if (error is UsecaseException<LEFT>) {
          return error.failure;
        }
        return onError?.call(error, s) ?? wrapError(error, s);
      },
    );
  }
}

/// Internal wrapper for exceptions occurring in the data layer.
final class _DataLayerError<ISSUE extends Issue> implements Exception {
  const _DataLayerError(this.issue);

  final ISSUE issue;
}
