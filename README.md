# cool_bedrock

A bedrock package providing the blueprints and abstract definitions necessary to build a scalable and maintainable Dart/Flutter application.

[![Pub Version](https://badgen.net/pub/v/cool_bedrock)](https://pub.dev/packages/cool_bedrock/)
[![Pub Likes](https://badgen.net/pub/likes/cool_bedrock)](https://pub.dev/packages/cool_bedrock/score)
[![Pub Points](https://badgen.net/pub/points/cool_bedrock)](https://pub.dev/packages/cool_bedrock/score)
[![Pub Downloads](https://badgen.net/pub/dm/cool_bedrock)](https://pub.dev/packages/cool_bedrock)
[![Dart SDK Version](https://badgen.net/pub/sdk-version/cool_bedrock)](https://pub.dev/packages/cool_bedrock/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/coolosos/cool_bedrock/blob/main/LICENSE)
[![](https://img.shields.io/badge/linted%20by-coolint-0553B1)](https://pub.dev/packages/coolint)
[![codecov](https://codecov.io/gh/coolosos/cool_bedrock/graph/badge.svg)](https://codecov.io/gh/coolosos/cool_bedrock)

---

## ✨ Features

- 🏛️ Formalized Architecture: Strict base contracts for all layers: Entity, Params, AppService, and Codable.
- 🎯 Domain Logic (Use Cases): Typified UseCase hierarchy for commands and queries, including assisted flow management (UseCaseHandler).
- 🛡️ Functional Error Handling: Leverages the functional types Either<Failure, T> and Option<T> for explicit, predictable, and boilerplate-reducing error flow.
- 🛑 Typed Errors: Coherent error structure using sealed base classes: Issue, Failure (business logic), RepositoryError, and DataSourceException (technical/infrastructure).
- 🔄 Reactive Services: Base classes for creating services that manage state using BehaviorSubject, PublishSubject, and periodic execution logic (Timer).
- 🧪 Immutability & Testability: All core domain structures (Entity, Params) are immutable and comparable (Equatable).

## 🚀 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  cool_bedrock: ^1.0.0
```

Then run:

```bash
dart pub get
```

## 📆 Usage

### Basic usage

```dart
import 'package:cool_bedrock/cool_bedrock.dart';
```

### 1. Creating the Use Case

This example demonstrates how to implement a UseCase, defining its specific Failure and parameter validation:

```dart
// 1. Define the specific Failure for this domain
sealed class FetchUserFailure extends Failure{
  const FetchUserFailure();
}
final class InvalidUserFailure extends FetchUserFailure {
  const InvalidUserFailure() : super(message: 'Invalid User ID provided.');
}
final class InvalidParamsUserFailure extends FetchUserFailure {
  const InvalidParamsUserFailure() : super(message: 'Invalid parameters provided.');
}

// 2. Implement the UseCase contract
final class FetchUserUseCase
    extends UseCase<UserEntity, FetchUserParams, FetchUserFailure> {
  const FetchUserUseCase(this.repository);

  final UserRepository repository;

  // Called automatically if params.isNotValid is true.
  @override
  FetchUserFailure onInvalidParams() => const InvalidParamsUserFailure();

  @override
  Future<Either<FetchUserFailure, UserEntity>> execute(
      FetchUserParams params) async {
    // Core logic goes here. Mappers and Repositories are typically called here.
    try {
      final user = await repository.fetch(params.userId);
      return Right(user); // Success
    } catch (e) {
      // Map low-level errors to high-level domain failures
      return const Left(InvalidUserFailure()); // Failure
    }
  }
}

final class FetchUserUseCaseHandle
    extends
        UseCaseHandler<
          UserEntity,
          AuthParams,
          FetchUserFailure,
          RepositoryValue
        > {
  const LoginUsecaseHandler({
    required LoginRepository repository,
  });

  final UserRepository repository;

  // Called automatically if params.isNotValid is true.
  @override
  FetchUserFailure onInvalidParams() => const InvalidParamsUserFailure();

  //Obtain repository values. Multiple repository can be call.
  @override
  Future<RepositoryValue> obtainValues(
    Resolver<FetchUserFailure> $,
    AuthParams params,
  ) async {
    final user = await $(
      getValue(
        () => repository.fetch(params.userId),
      ),
    );
    return user;
  }

  @override
  UserEntity transformation(
    RepositoryValue values,
  ) {
    if(values.name == null || values.name.isEmpty){
      throw const UsecaseException(InvalidUserFailure());
    }
    //Can throw exception of any kind and it will be control by [wrapError]
    return values.toEntity()
  }

  @override
  FetchUserFailure wrapError(Object error, StackTrace stackTrace) {
    return const InvalidUserFailure();
  }
}

```

### 2. Execution and Error Handling

```dart
// Execution with valid parameters
final validParams = const FetchUserParams('user_123');
final validResult = await fetchUserUsecase.call(validParams);

validResult.fold(
  // LEFT side (Failure)
  (failure) => print('Error: ${failure.message}'),
  // RIGHT side (Success)
  (user) => print('Fetched User: ${user.name}'),
);

```

## 💡 Reactive Services Example

The base services provide lifecycle control and reactivity. Here's a service that periodically updates a counter:

```dart
import 'package:cool_bedrock/cool_bedrock.dart';
import 'dart:async';

final class HeartbeatService extends TimerAndBehaviorService<int> {
  HeartbeatService()
      : super(periodicDuration: const Duration(seconds: 10));

  int _counter = 0;

  @override
  Future<void> work() async {
    // Logic that runs every 10 seconds
    _counter++;
    // Emit the new value to all subscribers
    add(_counter);
  }

  // start(), stop(), and dispose() logic is inherited and controlled externally.
}

```

## 📚 API Reference

Check the full API reference, including all generic types and abstract classes, on [pub.dev → cool_bedrock](https://pub.dev/documentation/cool_bedrock/latest/).

---

# Authors & Maintainers

This project was created and is primarily maintained by:

*   **[Cayetano Bañón Rubio](https://github.com/Mithos5r)**
*   **[Coolosos](https://github.com/coolosos)**

## 🤝 Contributing

Contributions are welcome!

- Open issues for bugs or feature requests
- Fork the repo and submit a PR
- Run `dart format` and `dart test` before submitting

---

## 🧪 Testing

To run tests and see code coverage:

```bash
dart test
```

---

## 📄 License

MIT © 2025 [Coolosos](https://github.com/coolosos)
