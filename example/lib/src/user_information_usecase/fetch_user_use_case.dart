import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:example_cool_bedrock/data/user/user_repository.dart';
import 'package:example_cool_bedrock/domain/usecase/user_information_usecase.dart';

import 'package:example_cool_bedrock/src/user_information_usecase/user_remote2_entity.dart';

/// {@macro example_cool_bedrock.usecase}
final class FetchUserUseCase extends UserInformationUsecase {
  /// {@macro example_cool_bedrock.usecase}
  const FetchUserUseCase(this.repository);

  final UserRepository repository;

  // Called automatically if params.isNotValid is true.
  @override
  FetchUserFailure onInvalidParams() => const InvalidParamsUserFailure();

  @override
  Future<Either<FetchUserFailure, UserEntity>> execute(
    AuthParams params,
  ) async {
    // Core logic goes here. Mappers and Repositories are typically called here.
    try {
      final user = await repository.call(userId: params.userId);
      if (user.toNullable()?.toEntity() case final user?) {
        return Right(user); // Success
      }
      throw const UsecaseException(InvalidParamsUserFailure());
    } catch (e) {
      // Map low-level errors to high-level domain failures
      if (e is UsecaseException<InvalidParamsUserFailure>) {
        return Left(e.failure);
      }
      return const Left(InvalidUserFailure()); // Failure
    }
  }
}
