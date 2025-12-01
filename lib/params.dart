import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// {@template cool_bedrock.params}
/// The abstract base class for all input parameter objects passed to a Usecase.
///
/// By enforcing a single, typed object as input, the Usecase signature
/// remains stable, improving maintainability and clarity even if the
/// required parameters change.
///
/// All concrete parameter classes must be immutable and define validation logic.
/// {@endtemplate}
@immutable
abstract class Params with EquatableMixin {
  /// {@macro cool_bedrock.params}
  const Params();

  /// Checks if the parameters contained within this object are valid for
  /// Usecase execution (e.g., non-null, correct format, etc.).
  ///
  /// Concrete classes must implement this logic.
  bool get isValid;

  /// Returns the inverse of [isValid]. True if the parameters are not valid.
  bool get isNotValid => !isValid;
}

/// {@template cool_bedrock.no_params}
/// A specific implementation of [Params] used as a sentinel value for
/// Usecase that require no input parameters.
///
/// This ensures type safety and avoids passing `null` for the parameters
/// argument of a Usecase.
/// {@endtemplate}
class NoParams extends Params {
  /// {@macro cool_bedrock.no_params}
  const NoParams();

  /// Always returns true, as there are no parameters to validate.
  @override
  bool get isValid => true;

  @override
  List<Object?> get props => [];
}

/// A constant instance of [NoParams] to be reused everywhere no parameters are needed.
const NoParams noParams = NoParams();
