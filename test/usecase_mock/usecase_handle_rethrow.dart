import 'dart:async';

import 'package:cool_bedrock/src/domain/usecase.dart';
import 'package:fpdart/src/either.dart';

final class UsecaseTestHandlerRethrowEntity extends Entity {
  const new({required this.throwError});

  final bool throwError;
  @override
  List<Object?> get props => [];
}

final class UsecaseTestHandlerRethrowParams extends Params {
  const new({required this.validate});

  final bool validate;

  @override
  bool get isValid => validate;

  @override
  List<Object?> get props => [validate];
}

sealed class UsecaseTestHandlerRethrowFailure extends Failure {
  const new();

  @override
  List<Object?> get props => [];
}

final class InvalidUsecaseTestHandlerRethrowParamsFailure
    extends UsecaseTestHandlerRethrowFailure {
  const new();
}

final class InvalidUsecaseTestHandlerRethrowFailure
    extends UsecaseTestHandlerRethrowFailure {
  const new();
}

final class UsecaseTestHandlerRethrow
    extends
        UseCaseHandler<
          UsecaseTestHandlerRethrowEntity,
          UsecaseTestHandlerRethrowParams,
          UsecaseTestHandlerRethrowFailure,
          UsecaseTestHandlerRethrowEntity
        > {
  const new({required this.repository});

  final Future<Either<Failure, UsecaseTestHandlerRethrowEntity>> Function()
  repository;
  @override
  InvalidUsecaseTestHandlerRethrowParamsFailure onInvalidParams() {
    return const InvalidUsecaseTestHandlerRethrowParamsFailure();
  }

  @override
  Future<UsecaseTestHandlerRethrowEntity> obtainValues(
    Resolver<UsecaseTestHandlerRethrowFailure> $,
    UsecaseTestHandlerRethrowParams params,
  ) async {
    final result = await $(
      getValue(
        repository.call,
        onLeft: (issue) =>
            throw UnsupportedError('Test that not control error are manage'),
        onError: (error, stack) =>
            const InvalidUsecaseTestHandlerRethrowFailure(),
      ),
    );

    return result;
  }

  @override
  UsecaseTestHandlerRethrowEntity transformation(
    UsecaseTestHandlerRethrowEntity values,
  ) {
    if (values.throwError) {
      throw UnsupportedError('Exception throw');
    }
    return values;
  }

  @override
  UsecaseTestHandlerRethrowFailure wrapError(
    Object error,
    StackTrace stackTrace,
  ) {
    return const InvalidUsecaseTestHandlerRethrowFailure();
  }
}

final class UsecaseTestHandlerOnLeft
    extends
        UseCaseHandler<
          UsecaseTestHandlerRethrowEntity,
          UsecaseTestHandlerRethrowParams,
          UsecaseTestHandlerRethrowFailure,
          UsecaseTestHandlerRethrowEntity
        > {
  const new({required this.repository});

  final Future<Either<Failure, UsecaseTestHandlerRethrowEntity>> Function()
  repository;
  @override
  InvalidUsecaseTestHandlerRethrowParamsFailure onInvalidParams() {
    return const InvalidUsecaseTestHandlerRethrowParamsFailure();
  }

  @override
  Future<UsecaseTestHandlerRethrowEntity> obtainValues(
    Resolver<UsecaseTestHandlerRethrowFailure> $,
    UsecaseTestHandlerRethrowParams params,
  ) async {
    final result = await $(getValue(repository.call));

    return result;
  }

  @override
  UsecaseTestHandlerRethrowEntity transformation(
    UsecaseTestHandlerRethrowEntity values,
  ) {
    if (values.throwError) {
      throw UnsupportedError('Exception throw');
    }
    return values;
  }

  @override
  UsecaseTestHandlerRethrowFailure wrapError(
    Object error,
    StackTrace stackTrace,
  ) {
    return const InvalidUsecaseTestHandlerRethrowFailure();
  }
}
