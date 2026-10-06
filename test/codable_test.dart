import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'codable_mock/codable_mock.dart';

void main() {
  group('JsonBytesCodable', () {
    test('should decode a JSON object into the concrete model', () {
      const model = BytesUserMock();

      final user = model.decode(utf8Bytes('{"name":"Coolosos","age":30}'));

      expect(user.name, equals('Coolosos'));
      expect(user.age, equals(30));
    });

    test('should return a JSON object as a map', () {
      const model = BytesUserMock();

      expect(
        model.deserialize(utf8Bytes('{"name":"Coolosos","age":30}')),
        equals({'name': 'Coolosos', 'age': 30}),
      );
    });

    test('should wrap a JSON array into a data map', () {
      const model = BytesUserMock();

      expect(
        model.deserialize(utf8Bytes('[{"id":1},{"id":2}]')),
        equals({
          'data': [
            {'id': 1},
            {'id': 2},
          ],
        }),
      );
      expect(
        model.decode(utf8Bytes('[{"id":1}]')),
        isA<BytesUserMock>(),
        reason:
            'decode should delegate to instanceFromMap with the wrapped map',
      );
    });

    test('should throw an ArgumentError naming the decoded payload type', () {
      const model = BytesUserMock();

      expect(
        () => model.deserialize(utf8Bytes('42')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Unsupported type for deserialization: int',
          ),
        ),
      );
      expect(
        () => model.deserialize(utf8Bytes('"just a string"')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Unsupported type for deserialization: String',
          ),
        ),
      );
      expect(
        () => model.deserialize(utf8Bytes('true')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Unsupported type for deserialization: bool',
          ),
        ),
      );
      expect(
        () => model.deserialize(utf8Bytes('1.5')),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Unsupported type for deserialization: double',
          ),
        ),
      );
      expect(
        () => model.decode(utf8Bytes('"just a string"')),
        throwsArgumentError,
      );
    });

    test('should fail on malformed bytes once they break the JSON', () {
      const model = BytesUserMock();

      // 0xC3 starts a two byte sequence and 0x28 cannot continue it, so the
      // lenient decoder produces a replacement char and the JSON is invalid.
      expect(
        () => model.deserialize(Uint8List.fromList([0xC3, 0x28, 0x7B])),
        throwsFormatException,
      );
    });

    test('should expose utf8 encoding and JsonCodec by default', () {
      const model = BytesUserMock();

      expect(model.encoding, isA<Utf8Codec>());
      expect(model.serializer, isA<JsonCodec>());
      expect(model.stringify, isTrue);
    });

    test('should compare models by props', () {
      expect(
        const BytesUserMock(name: 'Coolosos'),
        equals(const BytesUserMock(name: 'Coolosos')),
      );
      expect(
        const BytesUserMock(name: 'Coolosos'),
        isNot(equals(const BytesUserMock(name: 'Other'))),
      );
      expect(
        const BytesUserMock(name: 'Coolosos').hashCode,
        equals(const BytesUserMock(name: 'Coolosos').hashCode),
      );
    });
  });

  group('JsonStringCodable', () {
    test('should decode a JSON object into the concrete model', () {
      const model = StringUserMock();

      final user = model.decode('{"name":"Coolosos"}');

      expect(user.name, equals('Coolosos'));
    });

    test('should keep non ascii characters intact', () {
      const model = StringUserMock();

      final accented = model.decode('{"name":"Cayetano Bañón"}');
      final symbols = model.decode('{"name":"Cayetano Bañón ✅ 👨‍👩‍👧"}');

      expect(accented.name, equals('Cayetano Bañón'));
      expect(symbols.name, equals('Cayetano Bañón ✅ 👨‍👩‍👧'));
    });

    test('should return a JSON object as a map', () {
      const model = StringUserMock();

      expect(
        model.deserialize('{"name":"Coolosos"}'),
        equals({'name': 'Coolosos'}),
      );
    });

    test('should wrap a JSON array into a data map', () {
      const model = StringUserMock();

      expect(
        model.deserialize('[1,2]'),
        equals({
          'data': [1, 2],
        }),
      );
      expect(
        model.decode('[1,2]'),
        isA<StringUserMock>(),
        reason:
            'decode should delegate to instanceFromMap with the wrapped map',
      );
    });

    test('should throw an ArgumentError naming the decoded payload type', () {
      const model = StringUserMock();

      expect(
        () => model.deserialize('"just a string"'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Unsupported type for deserialization: String',
          ),
        ),
      );
      expect(
        () => model.deserialize('null'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Unsupported type for deserialization: null',
          ),
        ),
      );
    });

    test('should decode normally when a model overrides encoding to null', () {
      const model = NoEncodingUserMock();

      expect(model.encoding, isNull);
      expect(
        model.deserialize('{"name":"Coolosos"}'),
        equals({'name': 'Coolosos'}),
      );
      expect(model.decode('{"name":"Coolosos"}').name, equals('Coolosos'));
    });

    test('should wrap a JSON array regardless of the encoding', () {
      const model = NoEncodingUserMock();

      expect(
        model.deserialize('[1,2]'),
        equals({
          'data': [1, 2],
        }),
      );
    });

    test('should keep non ascii characters intact with a null encoding', () {
      const model = NoEncodingUserMock();

      final user = model.decode('{"name":"Cayetano Bañón"}');

      expect(user.name, equals('Cayetano Bañón'));
    });

    test('should expose utf8 encoding, JsonCodec and stringify by default', () {
      const model = StringUserMock();

      expect(model.encoding, isA<Utf8Codec>());
      expect(model.serializer, isA<JsonCodec>());
      expect(model.stringify, isTrue);
    });

    test('should compare models by props', () {
      expect(
        const StringUserMock(name: 'Coolosos'),
        equals(const StringUserMock(name: 'Coolosos')),
      );
      expect(
        const StringUserMock(name: 'Coolosos'),
        isNot(equals(const StringUserMock(name: 'Other'))),
      );
    });
  });
}
