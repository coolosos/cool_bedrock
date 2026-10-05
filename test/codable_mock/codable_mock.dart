import 'dart:convert';
import 'dart:typed_data';

import 'package:cool_bedrock/cool_bedrock.dart';

/// Concrete model to exercise the [JsonBytesCodable] contract.
final class BytesUserMock extends JsonBytesCodable<BytesUserMock> {
  const new({this.name, this.age});

  final String? name;
  final int? age;

  @override
  BytesUserMock instanceFromMap(Map<String, dynamic> data) =>
      BytesUserMock(name: data['name'] as String?, age: data['age'] as int?);

  @override
  List<Object?> get props => [name, age];
}

/// Concrete model to exercise the [JsonStringCodable] contract.
final class StringUserMock extends JsonStringCodable<StringUserMock> {
  const new({this.name});

  final String? name;

  @override
  StringUserMock instanceFromMap(Map<String, dynamic> data) =>
      StringUserMock(name: data['name'] as String?);

  @override
  List<Object?> get props => [name];
}

/// Same as [StringUserMock] but without an [Encoding], so the deserialization
/// has to fall back to the plain JSON serializer.
final class NoEncodingUserMock extends JsonStringCodable<NoEncodingUserMock> {
  const new({this.name});

  final String? name;

  @override
  Encoding? get encoding => null;

  @override
  NoEncodingUserMock instanceFromMap(Map<String, dynamic> data) =>
      NoEncodingUserMock(name: data['name'] as String?);

  @override
  List<Object?> get props => [name];
}

/// Encodes [value] as UTF-8 bytes, mimicking a raw HTTP payload.
Uint8List utf8Bytes(String value) => Uint8List.fromList(utf8.encode(value));
