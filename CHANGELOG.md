## 3.0.0

### ⚠️ Breaking changes
- Minimum Dart SDK is now `>=3.13.0`
- `equatable` upgraded to `^3.0.0`: `Entity`, `Params`, `Issue` and `Codable` now extend `Equatable` instead of using a mixin, and `Codable.serializer` is now typed as `Codec<dynamic, dynamic>`

### 🐛 Bug fixes
- `JsonStringCodable.deserialize` now parses the incoming `String` directly instead of pushing its UTF-16 code units through the UTF-8 decoder: every character above `U+007F` was corrupted or made the payload fail with a `FormatException`
- `Codable.encoding` is informative for `String` payloads (the transport already decoded them); only `JsonBytesCodable` uses it to decode bytes

### 📦 Dependencies
- `meta` upgraded to `^1.19.0` and `test` to `^1.32.0`

### 🧹 Internal
- Analysis options migrated to `package:coolint/dart.yaml` and updated to `coolint` `3.0.0`
- Constructors migrated to the primary constructor syntax
- `unnecessary_await_in_return` lint disabled: it is deprecated since Dart 3.13 and contradicts `async_return_with_no_await`
- Documentation references fixed and the README examples updated to the current API

## 2.0.0
### ⚠️ Breaking changes
- Change codable naming and field extend

## 1.0.1
- ✏️ Example and documentation
- ✏️ Test coverage

## 1.0.0 - 2025-12-2

- Initial version.
### Added
- Entity abstract
- Params abstract
- Case, Usecase, UsecaseHandle, OneWayUseCase, OneWayFailureUseCase abstract
- Issue, Failure, RepositoryError, DataSourceException, UsecaseException added
- Service added
- Codable abstract and implementations
- Observer abstract for classes added
