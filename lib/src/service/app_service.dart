library;

import 'dart:async';

import 'package:rxdart/rxdart.dart';

//Services that works with publish subject
part 'stream_base/publish_subject/publish_subject_service.dart';
part 'stream_base/publish_subject/timer_and_publish_service.dart';

//Services that works with publish subject
part 'stream_base/behavior_subject/behavior_subject_service.dart';
part 'stream_base/behavior_subject/timer_and_behavior_service.dart';
part 'stream_base/single_replay_subject/single_replay_subject_service.dart';

/// {@template cool_bedrock.app_service}
/// A core contract defining the lifecycle of a long-running service
/// or component within the application.
///
/// Implementations of [AppService] are typically responsible for
/// managing resources, subscriptions, streams, or background tasks
/// that need explicit initiation and termination.
///
/// This contract helps ensure controlled resource management and application
/// shutdown procedures.
/// {@endtemplate}
abstract interface class AppService {
  /// {@macro cool_bedrock.app_service}
  const AppService();

  /// Initializes and starts the service, setting up necessary resources
  /// and starting background tasks or listeners.
  ///
  /// If the service performs asynchronous initialization (e.g., fetching
  /// configurations), this method should be asynchronous.
  void start();

  /// Stops the service and releases all managed resources (e.g., closing
  /// database connections, canceling streams, disposing controllers).
  ///
  /// This method should be idempotent (calling it multiple times should
  /// not cause issues).
  void stop();
}
