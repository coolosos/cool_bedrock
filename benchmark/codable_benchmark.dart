import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

/// Measures how a `String` JSON payload is turned into Dart objects, comparing
/// the decoding strategies that `Codable` can use.
///
/// `fuse` only chains converters: `_FusedConverter.convert` is
/// `_second.convert(_first.convert(input))`, so the intermediate `String`
/// still exists. When the source is already a `String`, building it from
/// `codeUnits` is pure overhead: one `List<int>` allocation plus a second
/// `String` with the same content.
///
/// Run it with:
///
/// ```sh
/// dart run benchmark/codable_benchmark.dart [repetitions]
/// ```
final Converter<List<int>, Object?> _fused = const Utf8Codec(
  allowMalformed: true,
).decoder.fuse(const JsonDecoder());
const _codec = JsonCodec();

/// Keeps the decoded value alive so the VM cannot optimize the call away.
Object? sink;

/// Mirrors the previous `JsonStringCodable.deserialize`: UTF-16 code units
/// reinterpreted as UTF-8 bytes.
Object? _fusedCodeUnits(String payload) => _fused.convert(payload.codeUnits);

/// What `serializer.decode` does: parse the `String` directly.
Object? _directDecode(String payload) => _codec.decode(payload);

/// The only `fuse` based variant that is correct for a `String`: it encodes
/// the string to real UTF-8 bytes first, then decodes them back.
Object? _fusedViaBytes(String payload) => _fused.convert(utf8.encode(payload));

/// Reference point: the `Uint8List` path of `JsonBytesCodable`.
Object? _fusedFromBytes(Uint8List bytes) => _fused.convert(bytes);

class _DecodeBenchmark extends BenchmarkBase {
  new(super.name, this._decode);

  final Object? Function() _decode;

  @override
  void run() => sink = _decode();

  // Reports the time of a single run() instead of 10 calls.
  @override
  void exercise() => run();
}

void main(List<String> args) {
  _reportCorrectness();
  _reportTiming(args.isEmpty ? 3 : int.parse(args.first));
}

final _scenarios = <_Scenario>[
  _Scenario('tiny ascii', _asciiPayload(1)),
  _Scenario('medium ascii', _asciiPayload(50)),
  _Scenario('large ascii', _asciiPayload(5000)),
  _Scenario('large unicode', _unicodePayload(5000)),
];

void _reportCorrectness() {
  stdout.writeln('== Correctness ==');
  for (final scenario in _scenarios) {
    final reference = _preview(_directDecode(scenario.payload));
    final codeUnits = _attempt(() => _fusedCodeUnits(scenario.payload));
    final viaBytes = _attempt(() => _fusedViaBytes(scenario.payload));
    stdout
      ..writeln('${scenario.label} (${scenario.payload.length} chars)')
      ..writeln('  fused codeUnits ok: ${codeUnits == reference}')
      ..writeln('  fused via bytes ok: ${viaBytes == reference}')
      ..writeln('  expected value    : $reference')
      ..writeln('  codeUnits value   : $codeUnits');
  }
  stdout.writeln();
}

void _reportTiming(int repetitions) {
  stdout
    ..writeln('== Timing (min of $repetitions, us per decode) ==')
    ..writeln('${'variant'.padRight(20)}${'scenario'.padRight(16)}us/op');
  for (final scenario in _scenarios) {
    final bytes = Uint8List.fromList(utf8.encode(scenario.payload));
    final variants = <String, _Decode>{
      'direct decode': () => _directDecode(scenario.payload),
      'fused codeUnits': () => _fusedCodeUnits(scenario.payload),
      'fused via bytes': () => _fusedViaBytes(scenario.payload),
      'fused from bytes': () => _fusedFromBytes(bytes),
    };
    final baseline = _measure(variants['direct decode']!, repetitions);
    for (final variant in variants.entries) {
      final score = _runs(variant.value)
          ? _measure(variant.value, repetitions)
          : null;
      stdout.writeln(
        '${variant.key.padRight(20)}${scenario.label.padRight(16)}'
        '${score == null ? 'n/a' : score.toStringAsFixed(0).padLeft(7)}'
        '${score == null ? '   (throws)' : '   x${(score / baseline).toStringAsFixed(2)}'}',
      );
    }
  }
}

typedef _Decode = Object? Function();

/// Decodes and describes the result, or the error it throws.
String _attempt(_Decode decode) {
  try {
    return _preview(decode());
  } on Object catch (error) {
    return 'ERROR $error';
  }
}

bool _runs(_Decode decode) {
  try {
    decode();
    return true;
  } on Object {
    return false;
  }
}

double _measure(_Decode decode, int repetitions) {
  final scores = List<double>.generate(
    repetitions,
    (_) => _DecodeBenchmark('decode', decode).measure(),
  )..sort();
  return scores.first;
}

String _preview(Object? decoded) {
  final encoded = jsonEncode(decoded);
  return encoded.length <= 64 ? encoded : '${encoded.substring(0, 64)}...';
}

String _asciiPayload(int items) => jsonEncode(
  List<Map<String, Object?>>.generate(
    items,
    (index) => <String, Object?>{
      'id': index,
      'name': 'User $index',
      'email': 'user$index@coolosos.com',
      'active': index.isEven,
      'tags': const ['dart', 'flutter', 'fpdart'],
      'address': const {'city': 'Cali', 'country': 'Colombia', 'zip': '760001'},
    },
    growable: false,
  ),
);

String _unicodePayload(int items) => jsonEncode(
  List<Map<String, Object?>>.generate(
    items,
    (index) => <String, Object?>{
      'id': index,
      'name': 'Cayetano Bañón $index ✅',
      'email': 'cayetano$index@ejemplo.com',
      'active': index.isEven,
      'tags': const ['Bogotá', 'Cali', 'Bañón'],
      'address': const {
        'city': 'Bogotá',
        'country': 'Colombia',
        'zip': '760001',
      },
    },
    growable: false,
  ),
);

class _Scenario {
  const new(this.label, this.payload);

  final String label;
  final String payload;
}
