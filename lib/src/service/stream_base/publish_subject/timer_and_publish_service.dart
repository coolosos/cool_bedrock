part of '../../app_service.dart';

/// {@template cool_bedrock.timer_and_publish_service}
/// The base class for a reactive service that manages event emission using a [PublishSubject]
/// and periodically executes a core event generation logic using an internal [Timer].
///
/// This service is ideal for periodic, instantaneous event notifications or commands
/// (e.g., periodic log flushing, time-based reminders) where past state is irrelevant
/// to new subscribers.
/// {@endtemplate}
abstract base class TimerAndPublishService<T> implements AppService {
  /// {@macro cool_bedrock.timer_and_publish_service}
  TimerAndPublishService({required Duration periodicDuration})
    : _periodicDuration = periodicDuration;

  Timer? _timer;
  PublishSubject<T>? _publishSubject;
  final Duration _periodicDuration;

  /// Defines the core asynchronous work that must be executed periodically.
  ///
  /// This method is called repeatedly by the internal timer. Implementations
  /// should typically generate an event or command and then call [add]
  /// to broadcast it.
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
  /// It then starts the periodic timer that drives the service execution.
  @override
  void start() {
    if (_publishSubject == null || (_publishSubject?.isClosed ?? true)) {
      _publishSubject = PublishSubject();
    }
    if (_timer?.isActive ?? false) {
      _periodic();
      return;
    }
    _timer = Timer.periodic(_periodicDuration, (timer) async {
      await _periodic();
    });
  }

  /// Executes the core [work] asynchronously.
  Future<void> _periodic() async {
    await work();
  }

  /// Permanently disposes of the service, stopping the timer and closing the subject.
  void dispose() {
    stop();
    _publishSubject?.close();
  }

  /// Stops the periodic execution by canceling the internal timer.
  /// The [PublishSubject] remains open until [dispose] is called.
  @override
  void stop() {
    _timer?.cancel();
  }
}
