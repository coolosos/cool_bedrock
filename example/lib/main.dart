// ignore_for_file: avoid_print

import 'package:example_cool_bedrock/data/user/user_repository.dart';
import 'package:example_cool_bedrock/domain/usecase/user_information_usecase.dart';

// Note: In a real app, users should import from the main library file, not 'src'.
// Also, consider using dependency injection instead of manual instantiation
import 'package:example_cool_bedrock/src/data/user_repository/user_repository.dart';
import 'package:example_cool_bedrock/src/user_information_usecase/fetch_user_use_case.dart';
import 'package:example_cool_bedrock/src/user_information_usecase/user_information_usecase_handle.dart';

Future<void> main(List<String> args) async {
  print('🚀 Init Cool Bedrock Example');

  print('\n--- 1. Repository Creation ---');
  //Creation of data layer
  //Simulation of remote data obtain
  final UserRepository userRepository = MockUserRepository();
  print('✅ Mock repository initialized.');

  print('\n--- 2. UseCase Creation ---');
  // A. Standard Approach (Programmer manually handles execution)
  final UserInformationUsecase standardUseCase =
      FetchUserUseCase(userRepository);
  print('✅ Standard UseCase created.');

  // B. Programmatically handled
  final UserInformationUsecaseHandler handledUseCase =
      FetchUserUseCaseHandle(repository: userRepository);
  print('✅ Handled UseCase created.');

  print('\n--- 3. Scenario: Valid User (cool_bedrock) ---');
  const validParams = AuthParams(userId: 'cool_bedrock');
  // Calling the standard UseCase
  var result = await standardUseCase.call(validParams);
  print('Standard Response [${validParams.userId}]: $result');
  // Calling the handled UseCase
  result = await handledUseCase.call(validParams);
  print('Handled Response  [${validParams.userId}]: $result');

  print('\n--- 4. Scenario: Invalid User (other_bedrock) ---');
  const invalidParams = AuthParams(userId: 'other_bedrock');

  // Calling the standard UseCase
  result = await standardUseCase.call(invalidParams);
  print('Standard Response [${invalidParams.userId}]: $result');

  // Calling the handled UseCase
  result = await handledUseCase.call(invalidParams);
  print('Handled Response  [${invalidParams.userId}]: $result');
}
