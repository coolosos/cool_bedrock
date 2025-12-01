import 'package:test/test.dart';

import 'usecase_mock/usecase_mock.dart';

void main() {
  group('Usecase', () {
    late UsecaseTest usecaseTest;

    setUp(() {
      usecaseTest = UsecaseTest();
    });

    test('should throw invalid params exception', () async {
      final result = await usecaseTest.call(
        const UsecaseTestParams(validate: false),
      );
      expect(
        result.getLeft().toNullable(),
        isA<InvalidUsecaseTestParamsFailure>(),
      );
    });

    test('should throw other exception', () async {
      final result = await usecaseTest.call(
        const UsecaseTestParams(validate: true, giveResult: false),
      );
      expect(result.getLeft().toNullable(), isA<InvalidUsecaseTestFailure>());
    });

    test('should return entity', () async {
      final result = await usecaseTest.call(
        const UsecaseTestParams(validate: true, giveResult: true),
      );
      expect(result.toNullable() != null, true);
    });
  });
}
