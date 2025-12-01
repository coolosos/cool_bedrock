import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template cool_bedrock.codable}
/// The base contract for all data models or objects that require mapping
/// from a remote representation to a local Dart object (decoding/deserialization).
///
/// This abstract class enforces type safety for mapping operations and integrates
/// with [EquatableMixin] for reliable object comparison.
///
/// **Type Parameters:**
/// * **T**: The remote data type (e.g., `Map<String, dynamic>`, `String`, or `Uint8List`).
/// * **Self**: The concrete type of the implementing class, ensuring the [decode]
///   method returns an instance of the class that implements [Codable].
///   This is known as the **F-Bounded Polymorphism** pattern.
/// {@endtemplate}
@immutable
abstract class Codable<T, Self extends Codable<T, Self>> with EquatableMixin {
  /// {@macro cool_bedrock.codable}
  const Codable();

  /// The specific string encoding (e.g., 'utf-8') required for the remote data.
  ///
  /// Concrete implementations must provide the encoding used to interpret
  /// the remote data if applicable (e.g., when T is `String` or `Uint8List`).
  Encoding? get stringEncoding;

  /// The JSON codec (serializer) used to transform between raw JSON strings/bytes
  /// and Dart objects.
  ///
  /// This is typically provided by `dart:convert`.
  JsonCodec? get serializer;

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
  // coverage:ignore-start
  bool? get stringify => true;
  // coverage:ignore-end
}

@immutable
abstract class JsonBytesCodable<Self extends Codable<Uint8List, Self>>
    extends Codable<Uint8List, Self> {
  const JsonBytesCodable();

  @override
  Encoding get stringEncoding => const Utf8Codec(allowMalformed: true);
  @override
  JsonCodec get serializer => const JsonCodec();

  @protected
  Self instanceFromMap(Map<String, dynamic> data);

  @override
  Self decode(Uint8List remote) => instanceFromMap(deserialize(remote));

  Map<String, dynamic> deserialize(Uint8List remote) {
    final result =
        stringEncoding.decoder.fuse(serializer.decoder).convert(remote);
    if (result is Map<String, dynamic>) {
      return result;
    } else if (result is List<dynamic>) {
      return {'data': result};
    }
    throw ArgumentError(
      'Unsupported type for deserialization: ${remote.runtimeType}',
    );
  }
}

/// {@template cool_bedrock.json_bytes_codable}
/// A specialized abstract contract for decoding data models from a raw
/// byte array ([Uint8List]) that contains UTF-8 encoded JSON.
///
/// This class handles the essential steps for byte-to-model conversion:
/// 1. **Decoding Bytes:** Converts [Uint8List] to a raw JSON string using UTF-8.
/// 2. **Parsing JSON:** Converts the JSON string into a Dart [Map<String, dynamic>].
/// 3. **Model Mapping:** Delegates the final map-to-model conversion to [instanceFromMap].
/// {@endtemplate}
@immutable
abstract class JsonStringCodable<Self extends Codable<String, Self>>
    extends Codable<String, Self> {
  /// {@macro cool_bedrock.json_bytes_codable}
  const JsonStringCodable();

  /// Specifies the required string encoding for decoding the byte array.
  ///
  /// Fixed to **UTF-8** with permissive handling for malformed bytes.
  @override
  Encoding? get stringEncoding => const Utf8Codec(allowMalformed: true);

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

  /// Decodes the raw byte array [remote] into the concrete model instance [Self].
  ///
  /// This method orchestrates the byte-to-map conversion via [deserialize]
  /// and the map-to-instance conversion via [instanceFromMap].
  @override
  Self decode(String remote) => instanceFromMap(deserialize(remote));

  /// Performs the actual byte array to Dart Map deserialization using the
  /// defined [stringEncoding] and [serializer].
  ///
  /// Handles cases where the JSON array might represent a list of items
  /// (which is wrapped into a 'data' map key).
  ///
  /// - Parameters:
  ///   - remote: The raw [Uint8List] containing the JSON data.
  /// - Returns: The deserialized [Map<String, dynamic>].
  Map<String, dynamic> deserialize(String remote) {
    final Object? result;
    if (stringEncoding case final stringEncoding?) {
      result = stringEncoding.decoder
          .fuse(serializer.decoder)
          .convert(remote.codeUnits);
    } else {
      result = serializer.decode(remote);
    }
    if (result is Map<String, dynamic>) {
      return result;
    } else if (result is List<dynamic>) {
      return {'data': result};
    }
    throw ArgumentError(
      'Unsupported type for deserialization: ${remote.runtimeType}',
    );
  }
}
