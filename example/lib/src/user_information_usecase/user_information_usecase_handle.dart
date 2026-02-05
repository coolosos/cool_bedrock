import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:example_cool_bedrock/data/user/user_repository.dart';
import 'package:example_cool_bedrock/domain/usecase/user_information_usecase.dart';
import 'package:example_cool_bedrock/src/data/user_repository/user_repository.dart';

import 'package:example_cool_bedrock/src/user_information_usecase/user_remote2_entity.dart';

/// {@macro example_cool_bedrock.usecaseHandler}
final class FetchUserUseCaseHandle
    extends UserInformationUsecaseHandler<UserRemote> {
  /// {@macro example_cool_bedrock.usecaseHandler}
  const FetchUserUseCaseHandle({required this.repository});

  final UserRepository repository;

  // Called automatically if params.isNotValid is true.
  @override
  FetchUserFailure onInvalidParams() => const InvalidParamsUserFailure();

  //Obtain repository values. Multiple repository can be call.
  @override
  Future<UserRemote> obtainValues(
    Resolver<FetchUserFailure> $,
    AuthParams params,
  ) async {
    final user = await $(
      getValue(
        () => repository.call(userId: params.userId),
      ),
    );
    return user;
  }

  @override
  UserEntity transformation(
    UserRemote values,
  ) {
    if (values.name == null || (values.name ?? '').isEmpty) {
      throw const UsecaseException(InvalidUserFailure());
    }
    //Can throw exception of any kind and it will be control by [wrapError]
    return values.toEntity();
  }

  @override
  FetchUserFailure wrapError(Object error, StackTrace stackTrace) {
    return const InvalidUserFailure();
  }
}
