import 'package:cool_bedrock/cool_bedrock.dart';
import 'package:test/test.dart';

void main() {
  group('Domain test', () {
    test('Entity should have stringify enabled by default', () {
      const entity = MockEntity();
      expect(entity.stringify, isTrue);
      expect(entity.toString(), contains('MockEntity'));
    });

    test('Params should have stringify enabled by default', () {
      const param = MockParams();
      expect(param.stringify, isTrue);
      expect(param.toString(), contains('MockParams'));
    });

    test('No Params is always valid', () {
      expect(noParams.stringify, isTrue);
      expect(noParams.isValid, isTrue);
      expect(noParams.props, isEmpty);
    });
  });
}

final class MockEntity extends Entity {
  const MockEntity();

  @override
  List<Object?> get props => [];
}

final class MockParams extends Params {
  const MockParams();
  @override
  bool get isValid => true;

  @override
  List<Object?> get props => [];
}
