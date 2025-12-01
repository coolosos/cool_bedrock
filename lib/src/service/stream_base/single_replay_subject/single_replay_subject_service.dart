part of '../../app_service.dart';

/// {@template cool_bedrock.single_replay_subject_service}
/// A unique reactive service that buffers events when no listener is present.
///
/// Upon the **first** subscription to [stream], all buffered events are
/// emitted immediately (flushed) and the buffer is cleared.
///
/// After the initial flush, the stream behaves as a live, publish-style stream:
/// subsequent subscribers will only receive events occurring after their subscription.
/// This ensures buffered events are delivered exactly once to the first consumer.
///
/// **Best for:** Events that must not be missed during initialization, but are
/// irrelevant (and should not be repeated) for subsequent listeners.
/// {@endtemplate}
abstract base class SingleReplaySubjectService<T> implements AppService {
  /// {@macro cool_bedrock.single_replay_subject_service}
  SingleReplaySubjectService();

  /// Internal controller used for event management and broadcasting.
  /// It must be a broadcast stream since multiple listeners are possible.
  StreamController<T> _singleReplayController = StreamController<T>.broadcast();

  /// A temporary buffer holding events added before the first listener subscribes.
  final List<T> _noListenValues = [];
  // Defines the core work or subscription logic for this service.
  /// This is called within [start()] and should be implemented by concrete classes.
  Future<void> work();

  /// Provides access to the event stream.
  ///
  /// Flushes the buffer to the first subscriber and clears the buffer,
  /// ensuring the replay happens only once.
  Stream<T>? get stream => _singleReplayController.stream.doOnListen(() {
    for (final value in _noListenValues) {
      _singleReplayController.add(value);
    }
    _noListenValues.clear();
  });

  /// Adds a new event to the service.
  ///
  /// If the stream has an active listener, the event is added directly.
  /// If there are no active listeners, the event is stored in the buffer.
  void add(T event) {
    if (_singleReplayController.isClosed) {
      return;
    }
    return _singleReplayController.hasListener
        ? _singleReplayController.add(event)
        : _noListenValues.add(event);
  }

  /// Initializes and starts the service.
  ///
  /// If the stream controller was closed (e.g., after a previous [dispose]),
  /// a new one is created. It then calls [work()] for initial setup.
  @override
  void start() {
    if (_singleReplayController.isClosed) {
      _singleReplayController = StreamController<T>.broadcast();
    }

    work();
  }

  /// Cleans up all resources managed by this service.
  ///
  /// This method first calls [stop] to cease ongoing work and then permanently
  /// closes the underlying [StreamController].
  void dispose() {
    stop();
    _singleReplayController.close();
  }

  /// Stops any ongoing work.
  ///
  /// Concrete implementations must override this to stop specific activities
  /// initiated in [work]. The controller is NOT closed here.
  @override
  void stop() {}
}
