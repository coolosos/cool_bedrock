import 'package:fpdart/fpdart.dart';
import 'package:test/test.dart';

import 'usecase_mock/usecase_handle.dart';
import 'usecase_mock/usecase_handle_rethrow.dart';

void main() {
  group('Usecase', () {
    late UsecaseTestHandler usecaseTestSuccessHandler;
    late UsecaseTestHandler usecaseTestTransformThrowHandler;
    late UsecaseTestHandler usecaseTestFailHandler;
    late UsecaseTestHandler usecaseTestTransformThrowLeft;
    setUp(() {
      usecaseTestSuccessHandler = UsecaseTestHandler(
        repository: () => Future.value(
          const Right(
            UsecaseTestHandlerEntity(throwError: false, throwLeft: false),
          ),
        ),
      );
      usecaseTestFailHandler = UsecaseTestHandler(
        repository: () => throw UnimplementedError(),
      );
      usecaseTestTransformThrowHandler = UsecaseTestHandler(
        repository: () => Future.value(
          const Right(
            UsecaseTestHandlerEntity(throwError: true, throwLeft: false),
          ),
        ),
      );
      usecaseTestTransformThrowLeft = UsecaseTestHandler(
        repository: () => Future.value(
          const Right(
            UsecaseTestHandlerEntity(throwError: false, throwLeft: true),
          ),
        ),
      );
    });

    test('should throw invalid params exception', () async {
      final result = await usecaseTestSuccessHandler.call(
        const UsecaseTestHandlerParams(validate: false),
      );
      expect(
        result.getLeft().toNullable(),
        isA<InvalidUsecaseTestHandlerParamsFailure>(),
      );
    });

    test('should return entity', () async {
      final result = await usecaseTestSuccessHandler.call(
        const UsecaseTestHandlerParams(validate: true),
      );
      expect(result.toNullable() != null, true);
    });

    test('should throw failure', () async {
      final result = await usecaseTestFailHandler.call(
        const UsecaseTestHandlerParams(validate: true),
      );
      expect(result.getLeft().toNullable() != null, true);
    });

    test('should throw invalid failure in transform', () async {
      final result = await usecaseTestTransformThrowHandler.call(
        const UsecaseTestHandlerParams(validate: true),
      );
      expect(result.toNullable() == null, true);
    });

    test('should throw transformation failure in transform', () async {
      final result = await usecaseTestTransformThrowLeft.call(
        const UsecaseTestHandlerParams(validate: true),
      );

      expect(
        result.getLeft().toNullable(),
        isA<InvalidUsecaseTransformationFailure>(),
      );
    });

    test('should throw invalid failure in transform', () async {
      final usecaseNotControlError = UsecaseTestHandlerRethrow(
        repository: () =>
            Future.value(const Left(InvalidUsecaseTestHandlerRethrowFailure())),
      );

      final usecaseLeftRepository = UsecaseTestHandlerOnLeft(
        repository: () =>
            Future.value(const Left(InvalidUsecaseTestHandlerRethrowFailure())),
      );

      final manageThrow = await usecaseNotControlError.call(
        const UsecaseTestHandlerRethrowParams(validate: true),
      );
      expect(manageThrow.isLeft(), true);

      final manageLeft = await usecaseLeftRepository.call(
        const UsecaseTestHandlerRethrowParams(validate: true),
      );
      expect(manageLeft.isLeft(), true);
    });
  });
}
