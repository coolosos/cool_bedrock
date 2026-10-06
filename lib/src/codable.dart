import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template cool_bedrock.codable}
/// The base contract for all data models or objects that require mapping
/// from a remote representation to a local Dart object (decoding/deserialization).
///
/// This abstract class enforces type safety for mapping operations and integrates
/// with [Equatable] for reliable object comparison.
///
/// **Type Parameters:**
/// * **T**: The remote data type (e.g., `Map<String, dynamic>`, `String`, or `Uint8List`).
/// * **Self**: The concrete type of the implementing class, ensuring the [decode]
///   method returns an instance of the class that implements [Codable].
///   This is known as the **F-Bounded Polymorphism** pattern.
/// {@endtemplate}
@immutable
abstract class Codable<T, Self extends Codable<T, Self>> with Equatable {
  /// {@macro cool_bedrock.codable}
  const new();

  /// The specific string encoding (e.g., 'utf-8') required for the remote data.
  ///
  /// Concrete implementations must provide the encoding used to interpret
  /// the remote data if applicable (e.g., when T is `Uint8List`). It is not
  /// used when T is a `String`, because a Dart [String] is already decoded.
  Encoding? get encoding;

  /// The JSON codec (serializer) used to transform between raw JSON strings/bytes
  /// and Dart objects.
  ///
  /// This is typically provided by `dart:convert`.
  Codec<dynamic, dynamic>? get serializer;

  /// Decodes the remote data representation into an instance of the local Dart model.
  ///
  /// This factory-like method is responsible for validating and transforming
  /// the remote data type [T] into the specific concrete model [Self].
  ///
  /// - Parameters:
  ///   - remote: The remote data structure (e.g., a JSON map, string, or list).
  /// - Returns: An instance of the concrete model (`Self`).
  Self decode(T remote);

  @override
  bool? get stringify => true;
}

@immutable
abstract class JsonBytesCodable<Self extends Codable<Uint8List, Self>>
    extends Codable<Uint8List, Self> {
  const new();

  @override
  Encoding get encoding => const Utf8Codec(allowMalformed: true);
  @override
  JsonCodec get serializer => const JsonCodec();

  @protected
  Self instanceFromMap(Map<String, dynamic> data);

  @override
  Self decode(Uint8List remote) => instanceFromMap(deserialize(remote));

  Map<String, dynamic> deserialize(Uint8List remote) {
    final result = encoding.decoder.fuse(serializer.decoder).convert(remote);
    if (result is Map<String, dynamic>) {
      return result;
    } else if (result is List<dynamic>) {
      return {'data': result};
    }
    throw ArgumentError(
      'Unsupported type for deserialization: ${_jsonKind(result)}',
    );
  }
}

/// {@template cool_bedrock.json_string_codable}
/// A specialized abstract contract for decoding data models from a raw JSON
/// [String], typically the body of an HTTP response.
///
/// This class handles the essential steps for string-to-model conversion:
/// 1. **Parsing JSON:** Parses the [String] into a [Map<String, dynamic>].
/// 2. **Model Mapping:** Delegates the map-to-model conversion to
/// [instanceFromMap].
/// {@endtemplate}
@immutable
abstract class JsonStringCodable<Self extends Codable<String, Self>>
    extends Codable<String, Self> {
  /// {@macro cool_bedrock.json_string_codable}
  const new();

  /// Specifies the encoding used by the transport to decode the body.
  ///
  /// Fixed to **UTF-8**. The [String] handed to [deserialize] is already
  /// decoded by the transport, so this getter is informative only.
  @override
  Encoding? get encoding => const Utf8Codec(allowMalformed: true);

  /// Specifies the JSON serializer/deserializer.
  ///
  /// Fixed to the standard [JsonCodec].
  @override
  JsonCodec get serializer => const JsonCodec();

  /// Abstract factory method that converts the deserialized [Map<String, dynamic>]
  /// into the concrete model instance [Self].
  ///
  /// Concrete implementations *must* override this method to perform the final
  /// field mapping and validation.
  @protected
  Self instanceFromMap(Map<String, dynamic> data);

  /// Decodes the raw JSON [remote] into the concrete model instance [Self].
  ///
  /// This method orchestrates the string-to-map conversion via [deserialize]
  /// and the map-to-instance conversion via [instanceFromMap].
  @override
  Self decode(String remote) => instanceFromMap(deserialize(remote));

  /// Performs the actual JSON string to Dart Map deserialization using the
  /// defined [serializer].
  ///
  /// The [remote] string is parsed directly. Re-encoding it through [encoding]
  /// would only add work, and feeding its UTF-16 code units to a UTF-8 decoder
  /// corrupts every character above `U+007F`.
  ///
  /// Handles cases where the JSON array might represent a list of items
  /// (which is wrapped into a 'data' map key).
  ///
  /// - Parameters:
  ///   - remote: The raw [String] containing the JSON data.
  /// - Returns: The deserialized [Map<String, dynamic>].
  Map<String, dynamic> deserialize(String remote) {
    final Object? result = serializer.decode(remote);
    if (result is Map<String, dynamic>) {
      return result;
    } else if (result is List<dynamic>) {
      return {'data': result};
    }
    throw ArgumentError(
      'Unsupported type for deserialization: ${_jsonKind(result)}',
    );
  }
}

/// The kind of a decoded JSON value, as a stable, human-readable name.
///
/// `dart:convert` only ever produces `null`, `bool`, `num`, `String`, `List`
/// or `Map<String, dynamic>`. The containers are returned before this helper
/// is reached, so through the paired classes only the four JSON scalars occur;
/// the last case is a defensive guard (the serializer is a final [JsonCodec]).
///
/// The name is derived with type patterns instead of `runtimeType`, whose
/// string form is not contractually stable: obfuscated and minified release
/// builds rename user-defined types (see the `avoid_type_to_string` lint).
String _jsonKind(Object? value) => switch (value) {
  null => 'null',
  bool() => 'bool',
  int() => 'int',
  double() => 'double',
  String() => 'String',
  _ => 'unsupported value',
};
