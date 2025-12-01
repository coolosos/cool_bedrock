import 'package:meta/meta.dart';

/// {@template cool_bedrock.simple_observer}
/// A contract defining an observer for monitoring the creation and disposal
/// lifecycle events of specific components within the application (e.g., Services, Usecase).
///
/// This is particularly useful for centralized logging, debugging, or resource
/// tracking within the core architecture.
/// {@endtemplate}
abstract interface class SimpleObserver {
  /// {@macro cool_bedrock.simple_observer}
  const SimpleObserver();

  /// Called immediately after a component has been successfully created and initialized.
  ///
  /// - Parameters:
  ///   - name: The unique or descriptive name of the component that was created
  ///     (e.g., 'AuthService', 'FetchUserUsecase').
  @mustCallSuper
  void onCreate(String name) {}

  /// Called immediately before a component is permanently disposed of or closed.
  ///
  /// This signals that managed resources associated with the component are about
  /// to be released.
  ///
  /// - Parameters:
  ///   - name: The unique or descriptive name of the component that is being disposed.
  @mustCallSuper
  void onDispose(String name) {}
}
