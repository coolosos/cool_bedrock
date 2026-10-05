import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:test/test.dart';

import 'usecase_mock/usecase_composed_handler.dart';

void main() {
  const validParams = ComposedParams(validate: true);

  ComposedUseCaseHandler handlerWith({
    required Future<Either<Failure, String>> Function() first,
    required Future<Either<Failure, String>> Function() second,
  }) => ComposedUseCaseHandler(first: first, second: second);

  group('UsecaseFlowManager', () {
    test('should chain two getValue calls through the same resolver', () async {
      final usecase = handlerWith(
        first: () => Future.value(const Right('first')),
        second: () => Future.value(const Right('second')),
      );

      final result = await usecase.call(validParams);

      expect(
        result.toNullable(),
        equals(const ComposedEntity(value: 'first-second')),
      );
    });

    test(
      'should map a left through the onError callback of getValue',
      () async {
        final usecase = handlerWith(
          first: () => Future.value(const Left(ComposedRepositoryFailure())),
          second: () => Future.value(const Right('second')),
        );

        final result = await usecase.call(validParams);

        expect(
          result.getLeft().toNullable(),
          isA<ComposedRepositoryFailure>(),
          reason:
              'a Left must be mapped by onError before reaching the handler',
        );
      },
    );

    test(
      'should fall back to wrapError when getValue has no onLeft nor onError',
      () async {
        final usecase = handlerWith(
          first: () => Future.value(const Right('first')),
          second: () => Future.value(const Left(ComposedRepositoryFailure())),
        );

        final result = await usecase.call(validParams);

        expect(result.getLeft().toNullable(), isA<ComposedUnexpectedFailure>());
      },
    );

    test(
      'should map a thrown repository error through the onError callback',
      () async {
        final usecase = handlerWith(
          first: () => throw UnimplementedError(),
          second: () => Future.value(const Right('second')),
        );

        final result = await usecase.call(validParams);

        expect(result.getLeft().toNullable(), isA<ComposedRepositoryFailure>());
      },
    );

    test(
      'should fall back to wrapError when a callback without onError throws',
      () async {
        final usecase = handlerWith(
          first: () => Future.value(const Right('first')),
          second: () => throw UnimplementedError(),
        );

        final result = await usecase.call(validParams);

        expect(
          result.getLeft().toNullable(),
          isA<ComposedUnexpectedFailure>(),
          reason: 'getValue without onError must delegate to wrapError',
        );
      },
    );

    test(
      'should short circuit the chain when the first call is invalid',
      () async {
        var secondCalled = false;
        final usecase = handlerWith(
          first: () => Future.value(const Right('first')),
          second: () {
            secondCalled = true;
            return Future.value(const Right('second'));
          },
        );

        final result = await usecase.call(
          const ComposedParams(validate: false),
        );

        expect(
          result.getLeft().toNullable(),
          isA<ComposedInvalidParamsFailure>(),
        );
        expect(secondCalled, isFalse, reason: 'execute must not run');
      },
    );

    test(
      'should support fully synchronous obtainValues and transformation',
      () async {
        const usecase = SyncUseCaseHandler();

        final result = await usecase.call(validParams);

        expect(
          result.toNullable(),
          equals(const ComposedEntity(value: 'sync')),
        );
      },
    );

    test(
      'should propagate a typed UsecaseException thrown in transformation',
      () async {
        const usecase = TypedThrowUseCaseHandler();

        final result = await usecase.call(validParams);

        expect(result.getLeft().toNullable(), isA<ComposedUnexpectedFailure>());
      },
    );

    test('should keep concurrent calls isolated', () async {
      final usecase = handlerWith(
        first: () => Future<Either<Failure, String>>.delayed(
          const Duration(milliseconds: 10),
          () => const Right<Failure, String>('slow'),
        ),
        second: () => Future<Either<Failure, String>>.delayed(
          const Duration(milliseconds: 1),
          () => const Right<Failure, String>('fast'),
        ),
      );

      final results = await Future.wait([
        usecase.call(validParams),
        usecase.call(validParams),
      ]);

      expect(
        results.map((result) => result.toNullable()),
        everyElement(equals(const ComposedEntity(value: 'slow-fast'))),
      );
    });

    test('should keep concurrent calls with mixed outcomes isolated', () async {
      final usecase = handlerWith(
        first: () => Future<Either<Failure, String>>.delayed(
          const Duration(milliseconds: 10),
          () => const Right<Failure, String>('ok'),
        ),
        second: () => Future<Either<Failure, String>>.delayed(
          const Duration(milliseconds: 1),
          () => const Left<Failure, String>(ComposedRepositoryFailure()),
        ),
      );

      final results = await Future.wait([
        usecase.call(validParams),
        usecase.call(validParams),
        usecase.call(const ComposedParams(validate: false)),
      ]);

      expect(
        results[0].getLeft().toNullable(),
        isA<ComposedUnexpectedFailure>(),
      );
      expect(
        results[1].getLeft().toNullable(),
        isA<ComposedUnexpectedFailure>(),
      );
      expect(
        results[2].getLeft().toNullable(),
        isA<ComposedInvalidParamsFailure>(),
      );
    });
  });
}
