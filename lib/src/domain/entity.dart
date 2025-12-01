import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template cool_bedrock.entity}
/// The base contract for all domain entities in the application.
///
/// An **Entity** represents an object defined by its thread of continuity and
/// identity, rather than just the values of its attributes. Entities are typically
/// compared based on their unique identifier (e.g., an `id` field), but this
/// contract uses [Equatable] for value-based comparison of all properties
/// listed in [props].
///
/// Enforces that the object's state cannot change after creation, which is
/// a crucial principle for reliable state management  and testability within
/// the domain layer.
/// {@endtemplate}
@Immutable('Entities must be immutable')
abstract class Entity extends Equatable {
  /// {@macro cool_bedrock.entity}
  const Entity();
  // coverage:ignore-start
  @override
  List<Object?> get props;

  @override
  bool? get stringify => true;
  // coverage:ignore-end
}
