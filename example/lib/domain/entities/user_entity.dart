import 'package:cool_bedrock/cool_bedrock.dart';

final class UserEntity extends Entity {
  const UserEntity({
    required this.name,
    required this.surname,
    required this.birthday,
  });

  final String name;
  final String surname;
  final DateTime birthday;

  @override
  List<Object?> get props => [
        name,
        surname,
        birthday,
      ];
}
