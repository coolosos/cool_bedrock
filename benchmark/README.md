# Codable decoding benchmark

`codable_benchmark.dart` measures how a `String` JSON payload is turned into
Dart objects. It exists to settle one question with numbers instead of
intuition:

> Is `encoding.decoder.fuse(serializer.decoder).convert(remote.codeUnits)` a
> faster way to decode a `String` than letting the serializer parse it?

Short answer: **no, it is slower**, and it is also incorrect for any character
above `U+007F`. This benchmark is the evidence behind the change in
`JsonStringCodable.deserialize`.

## What `fuse` actually does

The name suggests a shortcut, but it only chains two converters
(`lib/convert/converter.dart`):

```dart
class _FusedConverter<S, M, T> extends Converter<S, T> {
  T convert(S input) => _second.convert(_first.convert(input));
}
```

The intermediate value is still materialized. Fusing pays off when the source
is **bytes**, because then `Utf8Decoder` produces the `String` once and hands it
straight to the JSON parser. When the source is already a `String`, the fused
call adds two allocations before the very same parse:

1. `remote.codeUnits` builds a `List<int>` of UTF-16 code units.
2. `Utf8Decoder.convert(...)` treats those units as UTF-8 bytes and builds a
   **second `String`** with the same content.
3. `JsonDecoder.convert(...)` parses it.

Step 2 is also where correctness breaks: UTF-16 code units are not UTF-8 bytes,
so every character above `U+007F` is mangled or makes the payload fail to parse.

## Variants

| Variant | Code | Notes |
| --- | --- | --- |
| `direct decode` | `serializer.decode(payload)` | The fix. Parses the `String` once. |
| `fused codeUnits` | `convert(payload.codeUnits)` | The previous implementation. |
| `fused via bytes` | `convert(utf8.encode(payload))` | The only correct `fuse` variant for a `String`: it encodes to real UTF-8 bytes first. |
| `fused from bytes` | `convert(Uint8List)` | Reference point for `JsonBytesCodable`, untouched by the change. |

## Payloads

| Scenario | Size | Content |
| --- | --- | --- |
| `tiny ascii` | 166 chars | One record, the shape of a typical API response. |
| `medium ascii` | 8.4 KB | 50 records. |
| `large ascii` | 869 KB | 5000 records. |
| `large unicode` | 944 KB | 5000 records with `ñ`, accented vowels and emoji. |

The unicode scenario is the one that fails with `fused codeUnits`.

## Running it

```sh
dart pub get
dart run benchmark/codable_benchmark.dart         # 3 repetitions (default)
dart run benchmark/codable_benchmark.dart 5       # 5 repetitions
```

It prints a correctness report first, then a timing table with the minimum of
the repetitions and the ratio against `direct decode`. It exits with `0` even
when a variant throws: this is a measurement tool, not a gate.

Benchmark files are analyzed by `dart analyze --fatal-infos` and checked by
cspell, so the payload only uses words the project dictionary already accepts
(`Bañón`, `Bogotá`, `Cali`, plus symbols). CI does not run benchmarks.

## Results

Measured on Dart 3.13.4, macOS 26.6.2, Apple M1 Pro, min of 3 repetitions.
Absolute numbers depend on the machine; the ratios are the meaningful part.

### Correctness

| Scenario | `fused codeUnits` | `fused via bytes` |
| --- | --- | --- |
| `tiny ascii` | ok | ok |
| `medium ascii` | ok | ok |
| `large ascii` | ok | ok |
| `large unicode` | **`FormatException: Control character in string`** | ok |

A real payload from the benchmark, decoded with `fused codeUnits`:

```
input:     [{"id":0,"name":"Cayetano Bañón 0 ✅", ... }]
expected:  [{"id":0,"name":"Cayetano Bañón 0 ✅", ... }]
codeUnits: ERROR FormatException: Control character in string (at offset 34)
```

Depending on the characters involved, the corruption shows up in two ways:

| Input | `fused codeUnits` |
| --- | --- |
| `{"name":"Cayetano Bañón"}` | `{name: Cayetano Ba��n}` (silent) |
| `{"name":"Bañón — dash"}` | `FormatException: Control character in string` |
| `{"name":"Bañón ✅"}` | `FormatException: Control character in string` |
| `{"name":"Cayetano Bañón ✅ 👨‍👩‍👧"}` | `FormatException: Control character in string` |

Characters in the Latin-1 range (`ñ`, `á`, `é`, `ö`, ...) become `U+FFFD`
replacement characters and the decode still returns, so nothing reports the
damage. Characters further away, such as an em dash or an emoji, shift the
parser enough to fail the whole payload.

The silent case is the dangerous one: the model is populated with garbage and
the failure surfaces much later, far from the response that caused it.

### Timing (µs per decode, ratio vs `direct decode`)

| Variant | `tiny ascii` | `medium ascii` | `large ascii` | `large unicode` |
| --- | --- | --- | --- | --- |
| `direct decode` | 1 (x1.00) | 46 (x1.00) | 5556 (x1.00) | 9855 (x1.00) |
| `fused codeUnits` | 1 (x1.01) | 45 (x0.97) | **6359 (x1.15)** | **throws** |
| `fused via bytes` | 1 (x1.24) | 57 (x1.22) | 8339 (x1.51) | 9726 (x0.98) |
| `fused from bytes` | 1 (x0.84) | 37 (x0.79) | 4599 (x0.83) | 6870 (x0.69) |

## Conclusions

1. **`fused codeUnits` was never faster.** It costs 15 % more on the large
   payload and is a tie on the small ones, where the fixed costs dominate. The
   overhead scales with the payload because the extra `List<int>` and the
   duplicated `String` are proportional to its size.
2. **There is no correct `fuse` alternative worth having.** `fused via bytes`
   is correct but 22-51 % slower on ASCII, so "keep the fused path and fix the
   bug" is not a trade-off: the fix is both faster and correct.
3. **`fuse` does pay off for bytes.** `fused from bytes`, which is what
   `JsonBytesCodable.deserialize` uses, is 16-31 % faster than parsing a
   `String`. That path was left untouched.

## The change

`lib/src/codable.dart`:

```dart
// before
final Object? result;
if (encoding case final stringEncoding?) {
  result = stringEncoding.decoder
      .fuse(serializer.decoder)
      .convert(remote.codeUnits);
} else {
  result = serializer.decode(remote);
}

// after
final Object? result = serializer.decode(remote);
```

`Codable.encoding` stays in the API, but for `String` payloads it is now
informative: the transport already produced a decoded `String`, so there is
nothing left to decode. `JsonBytesCodable` still uses it.

The regression test lives in `test/codable_test.dart` under
`should keep non ascii characters intact`.

## Methodology notes

- `BenchmarkBase.measure()` reports **microseconds** per `exercise()`, not
  nanoseconds; `exercise()` is overridden to call `run()` once so the score is
  one decode.
- The minimum of the repetitions is reported because it is the least noisy
  estimator here.
- Decoded values are stored in a top level `sink` so the VM cannot eliminate
  the call.
- Variants that throw are probed once and reported as `n/a (throws)` instead of
  timing an exception path.