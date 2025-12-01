import 'dart:async';

import 'package:cool_bedrock/src/domain/usecase.dart';
import 'package:cool_bedrock/src/errors/issue.dart';
import 'package:fpdart/src/either.dart';

final class UsecaseTestHandlerEntity extends Entity {
  const UsecaseTestHandlerEntity({
    required this.throwError,
    required this.throwLeft,
  });

  final bool throwError;
  final bool throwLeft;
  @override
  List<Object?> get props => [];
}

final class UsecaseTestHandlerParams extends Params {
  const UsecaseTestHandlerParams({required this.validate});

  final bool validate;

  @override
  bool get isValid => validate;

  @override
  List<Object?> get props => [validate];
}

sealed class UsecaseTestHandlerFailure extends Failure {
  const UsecaseTestHandlerFailure();

  @override
  List<Object?> get props => [];
}

final class InvalidUsecaseTestHandlerParamsFailure
    extends UsecaseTestHandlerFailure {
  const InvalidUsecaseTestHandlerParamsFailure();
}

final class InvalidUsecaseTestHandlerFailure extends UsecaseTestHandlerFailure {
  const InvalidUsecaseTestHandlerFailure();
}

final class InvalidUsecaseTransformationFailure
    extends UsecaseTestHandlerFailure {
  const InvalidUsecaseTransformationFailure();
}

final class UsecaseTestHandler
    extends
        UseCaseHandler<
          UsecaseTestHandlerEntity,
          UsecaseTestHandlerParams,
          UsecaseTestHandlerFailure,
          UsecaseTestHandlerEntity
        > {
  const UsecaseTestHandler({required this.repository});

  final Future<Either<Failure, UsecaseTestHandlerEntity>> Function() repository;
  @override
  InvalidUsecaseTestHandlerParamsFailure onInvalidParams() {
    return const InvalidUsecaseTestHandlerParamsFailure();
  }

  @override
  Future<UsecaseTestHandlerEntity> obtainValues(
    Resolver<UsecaseTestHandlerFailure> $,
    UsecaseTestHandlerParams params,
  ) async {
    final result = await $(
      getValue(
        repository.call,
        onError: (error, stack) => const InvalidUsecaseTestHandlerFailure(),
      ),
    );

    return result;
  }

  @override
  UsecaseTestHandlerEntity transformation(UsecaseTestHandlerEntity values) {
    if (values.throwError) {
      throw UnsupportedError('Exception throw');
    }
    if (values.throwLeft) {
      throw const UsecaseException(InvalidUsecaseTransformationFailure());
    }
    return values;
  }

  @override
  UsecaseTestHandlerFailure wrapError(Object error, StackTrace stackTrace) {
    return const InvalidUsecaseTestHandlerFailure();
  }
}
