import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:test/test.dart';

void main() {
  group('Error test', () {
    test('Issue should have stringify enabled by default', () {
      const failure = MockFailure();
      expect(failure.stringify, isTrue);
      expect(failure.toString(), contains('MockFailure'));
      expect(failure.message, isNotEmpty);
    });

    test('Error should have stringify enabled by default', () {
      const error = MockError();
      expect(error.stringify, isTrue);
      expect(error.toString(), contains('MockError'));
      expect(error.message, isNotEmpty);
    });

    test('Params should have stringify enabled by default', () {
      const exception = MockException();
      expect(exception.stringify, isTrue);
      expect(exception.toString(), contains('MockException'));
      expect(exception.message, isNotEmpty);
      expect(exception.props, isEmpty);
    });
  });
}

final class MockFailure extends Failure {
  const MockFailure() : super(message: 'message');

  @override
  List<Object?> get props => [];
}

final class MockError extends RepositoryError {
  const MockError() : super(message: 'message');

  @override
  List<Object?> get props => [];
}

final class MockException extends DataSourceException {
  const MockException()
      : super(
          message: 'Message',
          requestBody: null,
          requestHeaders: const {},
          requestUri: null,
        );

  @override
  List<Object?> get props => [];
}
