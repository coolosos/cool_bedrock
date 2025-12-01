part of '../../app_service.dart';

/// {@template cool_bedrock.publish_subject_service}
/// The base class for reactive services that manage events using a [PublishSubject].
///
/// A [PublishSubject] only broadcasts events to listeners that subscribe *after*
/// the event has been added. It does not replay old values, making it ideal
/// for transient, one-time events or commands (e.g., 'show error message', 'user logged out').
///
/// It implements the [AppService] contract, allowing for asynchronous setup
/// through the [start] method.
/// {@endtemplate}
abstract base class PublishSubjectService<T> implements AppService {
  /// {@macro cool_bedrock.publish_subject_service}
  PublishSubjectService();

  PublishSubject<T>? _publishSubject;

  /// Defines the core asynchronous work or subscription logic for this service.
  ///
  /// This method is called inside [start] and should be implemented by
  /// concrete classes to establish necessary subscriptions or perform initial setup.
  Future<void> work();

  /// Provides access to the underlying stream for external subscriptions.
  Stream<T>? get stream async* {
    final stream = _publishSubject?.stream;
    if (stream is Stream<T>) {
      yield* stream;
    }
  }

  /// Adds a new event to the subject, broadcasting it to all currently active listeners.
  ///
  /// The event is only added if the subject is currently open.
  void add(T event) {
    if (_publishSubject?.isClosed == false) {
      _publishSubject?.add(event);
    }
  }

  /// Initializes and starts the service asynchronously.
  ///
  /// A new [PublishSubject] is created if none exists or if the previous one was closed.
  /// It then awaits the completion of [work] before considering the service started.
  @override
  Future<void> start() async {
    if (_publishSubject == null || (_publishSubject?.isClosed ?? true)) {
      _publishSubject = PublishSubject();
    }

    await work();
  }

  /// Cleans up all resources managed by this service.
  ///
  /// This method first calls [stop] to cease ongoing work and then permanently
  /// closes the underlying [PublishSubject], making it unusable.
  void dispose() {
    stop();
    _publishSubject?.close();
  }

  /// Stops any ongoing work.
  ///
  /// Concrete implementations must override this to stop specific activities
  /// initiated in [work]. The subject is NOT closed here, allowing the service
  /// to be restarted later.
  @override
  void stop() {}
}
