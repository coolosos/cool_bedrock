import 'dart:async';

import 'package:cool_bedrock/cool_bedrock.dart';

final class ComposedEntity extends Entity {
  const new({required this.value});

  final String value;

  @override
  List<Object?> get props => [value];
}

final class ComposedParams extends Params {
  const new({required this.validate});

  final bool validate;

  @override
  bool get isValid => validate;

  @override
  List<Object?> get props => [validate];
}

sealed class ComposedFailure extends Failure {
  const new();

  @override
  List<Object?> get props => [];
}

final class ComposedInvalidParamsFailure extends ComposedFailure {
  const new();
}

/// Returned by the `onError` callback of the composed handler.
final class ComposedRepositoryFailure extends ComposedFailure {
  const new();
}

/// Returned by the `wrapError` callback when no other mapping applies.
final class ComposedUnexpectedFailure extends ComposedFailure {
  const new();
}

/// Chains two fallible data layer calls through the same [Resolver] and
/// transforms the result asynchronously.
final class ComposedUseCaseHandler
    extends
        UseCaseHandler<
          ComposedEntity,
          ComposedParams,
          ComposedFailure,
          String
        > {
  const new({required this.first, required this.second});

  final Future<Either<Failure, String>> Function() first;
  final Future<Either<Failure, String>> Function() second;

  @override
  ComposedInvalidParamsFailure onInvalidParams() =>
      const ComposedInvalidParamsFailure();

  @override
  Future<String> obtainValues(
    Resolver<ComposedFailure> $,
    ComposedParams params,
  ) async {
    final firstValue = await $(
      getValue(
        first,
        onError: (error, stack) => const ComposedRepositoryFailure(),
      ),
    );
    final secondValue = await $(getValue(second));

    return '$firstValue-$secondValue';
  }

  @override
  Future<ComposedEntity> transformation(String values) async {
    await Future<void>.delayed(Duration.zero);

    return ComposedEntity(value: values);
  }

  @override
  ComposedFailure wrapError(Object error, StackTrace stackTrace) =>
      const ComposedUnexpectedFailure();
}

/// Never touches a Future: it covers the synchronous [FutureOr] paths of the
/// flow manager.
final class SyncUseCaseHandler
    extends
        UseCaseHandler<
          ComposedEntity,
          ComposedParams,
          ComposedFailure,
          String
        > {
  const new();

  @override
  ComposedInvalidParamsFailure onInvalidParams() =>
      const ComposedInvalidParamsFailure();

  @override
  String obtainValues(Resolver<ComposedFailure> $, ComposedParams params) =>
      params.validate ? 'sync' : 'never';

  @override
  ComposedEntity transformation(String values) => ComposedEntity(value: values);

  @override
  ComposedFailure wrapError(Object error, StackTrace stackTrace) =>
      const ComposedUnexpectedFailure();
}

/// Fails inside [transformation] with a typed [UsecaseException].
final class TypedThrowUseCaseHandler extends SyncUseCaseHandler {
  const new();

  @override
  ComposedEntity transformation(String values) =>
      throw const UsecaseException(ComposedUnexpectedFailure());
}
