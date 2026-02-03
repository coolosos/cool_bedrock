import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:example_cool_bedrock/data/user/user_remote.dart';
import 'package:example_cool_bedrock/data/user/user_repository.dart';

export 'package:example_cool_bedrock/data/user/user_remote.dart';

final class MockUserRepository extends UserRepository {
  @override
  Future<Either<UserRepositoryError, UserRemote>> call({
    required String userId,
  }) async {
    if (userId.contains('cool_bedrock')) {
      return Right(
        UserRemote(
          name: 'Coolosos',
          surname: 'Flutter',
          birthday: DateTime(2020),
        ),
      );
    }
    return const Left(NoUserFindError());
  }
}
