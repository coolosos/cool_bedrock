import 'package:cool_bedrock/src/domain/usecase.dart';
import 'package:fpdart/src/either.dart';

final class UsecaseTestEntity extends Entity {
  @override
  List<Object?> get props => [];
}

final class UsecaseTestParams extends Params {
  const new({required this.validate, this.giveResult = false});

  final bool validate;

  final bool giveResult;

  @override
  bool get isValid => validate;

  @override
  List<Object?> get props => [validate];
}

sealed class UsecaseTestFailure extends Failure {
  const new();

  @override
  List<Object?> get props => [];
}

final class InvalidUsecaseTestParamsFailure extends UsecaseTestFailure {
  const new();
}

final class InvalidUsecaseTestFailure extends UsecaseTestFailure {
  const new();
}

final class UsecaseTest
    extends UseCase<UsecaseTestEntity, UsecaseTestParams, UsecaseTestFailure> {
  @override
  Future<Either<UsecaseTestFailure, UsecaseTestEntity>> execute(
    UsecaseTestParams params,
  ) {
    if (params.giveResult) {
      return Future.value(Right(UsecaseTestEntity()));
    }
    return Future.value(const Left(InvalidUsecaseTestFailure()));
  }

  @override
  InvalidUsecaseTestParamsFailure onInvalidParams() {
    return const InvalidUsecaseTestParamsFailure();
  }
}
