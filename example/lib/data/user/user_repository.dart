import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:example_cool_bedrock/data/user/user_remote.dart';

abstract base class UserRepository {
  Future<Either<UserRepositoryError, UserRemote>> call({
    required String userId,
  });
}

sealed class UserRepositoryError extends RepositoryError {
  const UserRepositoryError();
}

final class NoUserFindError extends UserRepositoryError {
  const NoUserFindError();
  @override
  List<Object?> get props => [message];
}
