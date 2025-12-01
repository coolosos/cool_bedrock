part of '../../app_service.dart';

/// {@template cool_bedrock.timer_and_behavior_service}
/// The base class for a reactive service that manages state using a [BehaviorSubject]
/// and periodically executes a core logic method using an internal [Timer].
///
/// This service is ideal for continuously updated data streams (e.g., real-time
/// synchronization, polling APIs, or time-based counters).
///
/// The state is managed by the [BehaviorSubject], and the execution rate is
/// controlled by the provided duration.
/// {@endtemplate}
abstract base class TimerAndBehaviorService<T> implements AppService {
  /// {@macro cool_bedrock.timer_and_behavior_service}
  TimerAndBehaviorService({required Duration periodicDuration})
      : _periodicDuration = periodicDuration,
        super();

  Timer? _timer;
  BehaviorSubject<T>? _behaviorSubject;
  final Duration _periodicDuration;

  /// Defines the core asynchronous work that must be executed periodically.
  ///
  /// This method is called repeatedly by the internal timer. Implementations
  /// should typically fetch data or calculate a new state and then call [add(T)]
  /// to update the stream.
  Future<void> work();

  /// Provides access to the underlying stream for external subscriptions.
  ///
  /// Returns the stream of the internal [BehaviorSubject] if it is active.
  Stream<T>? get stream async* {
    final stream = _behaviorSubject?.stream;
    if (stream != null) {
      yield* stream;
    }
  }

  /// Adds a new value to the subject, broadcasting it to all active listeners.
  void add(T event) {
    if (!(_behaviorSubject?.isClosed ?? true)) {
      _behaviorSubject?.add(event);
    }
  }

  /// Starts the service by initializing the [BehaviorSubject] (if necessary)
  /// and starting the periodic timer.
  @override
  void start() {
    if (_behaviorSubject == null || (_behaviorSubject?.isClosed ?? true)) {
      _behaviorSubject = BehaviorSubject<T>();
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
    _behaviorSubject?.close();
  }

  // Stops the periodic execution by canceling the internal timer.
  /// The [BehaviorSubject] remains open and retains its last value.
  @override
  void stop() {
    _timer?.cancel();
  }
}
