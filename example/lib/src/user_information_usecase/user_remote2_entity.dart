import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:example_cool_bedrock/data/user/user_remote.dart';
import 'package:example_cool_bedrock/domain/entities/user_entity.dart';
import 'package:example_cool_bedrock/domain/usecase/user_information_usecase.dart'
    show InvalidUserFailure;

extension UserRemote2Entity on UserRemote {
  UserEntity toEntity() {
    final name = this.name ?? '';
    final surname = this.surname ?? '';
    final birthday = this.birthday;

    if (name.isEmpty || surname.isEmpty || birthday == null) {
      throw const UsecaseException(InvalidUserFailure());
    }
    return UserEntity(name: name, surname: surname, birthday: birthday);
  }
}
