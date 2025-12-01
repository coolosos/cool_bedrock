part of '../../app_service.dart';

/// {@template cool_bedrock.behavior_subject_service}
/// The base class for reactive services that manage state using a [BehaviorSubject].
///
/// This service caches the latest value and replays it immediately to any new
/// subscriber. It implements the [AppService] contract for synchronous lifecycle
/// management ([start] and [stop]).
///
/// **Note:** This implementation ensures the internal [BehaviorSubject] is closed
/// only on [dispose], allowing [start] and [stop] to be used for transient
/// work management (e.g., managing timers or network subscriptions).
/// {@endtemplate}
abstract base class BehaviorSubjectService<T> implements AppService {
  /// {@macro cool_bedrock.behavior_subject_service}
  BehaviorSubjectService();

  BehaviorSubject<T>? _behaviorSubject;

  /// Defines the core work or subscription logic for this service.
  ///
  /// This method is called inside [start] and should be implemented by
  /// concrete classes to establish necessary subscriptions, timers, or logic.
  /// It is recommended this logic be non-blocking.
  Future<void> work();

  /// Provides access to the underlying stream for external subscriptions.
  Stream<T>? get stream async* {
    final stream = _behaviorSubject?.stream;
    if (stream != null) {
      yield* stream;
    }
  }

  /// Adds a new value to the subject, broadcasting it to all active listeners.
  ///
  /// The value is only added if the subject is currently open.
  void add(T event) {
    if (_behaviorSubject?.isClosed == false) {
      _behaviorSubject?.add(event);
    }
  }

  /// Initializes and starts the service.
  ///
  /// If the internal subject is not initialized or is closed, a new one is created.
  /// It then calls [work] to execute the core service logic.
  @override
  void start() {
    if (_behaviorSubject == null || (_behaviorSubject?.isClosed ?? true)) {
      _behaviorSubject = BehaviorSubject<T>();
    }

    work();
  }

  /// Cleans up all resources managed by this service.
  ///
  /// This method first calls [stop] to cease ongoing work and then permanently
  /// closes the underlying [BehaviorSubject], making it unusable.
  void dispose() {
    stop();
    _behaviorSubject?.close();
  }

  /// Stops any ongoing work (e.g., cancels timers or network subscriptions).
  ///
  /// Concrete implementations must override this to stop specific activities
  /// initiated in [work]. The subject is NOT closed here, allowing the service
  /// to be restarted.
  @override
  void stop() {}
}
