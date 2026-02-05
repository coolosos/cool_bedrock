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
  SingleReplaySubjectService({this.maxBufferSize});

  /// Internal controller used for event management and broadcasting.
  /// It must be a broadcast stream since multiple listeners are possible.
  StreamController<T>? _singleReplayController;

  /// A temporary buffer holding events added before the first listener subscribes.
  final List<T> _noListenValues = [];

  /// Security flag to track if the [_noListenValues] buffer was already delivered.
  bool _isFlushed = false;

  /// Maximum number of events to hold in the buffer.
  final int? maxBufferSize;

  /// Defines the core work or subscription logic for this service.
  /// This is called within [start()] and should be implemented by concrete classes.
  Future<void> work();

  /// Provides access to the event stream.
  ///
  /// Flushes the buffer to the first subscriber and clears the buffer,
  /// ensuring the replay happens only once.
  Stream<T> get stream {
    _ensureController();
    final proxyController = StreamController<T>();

    proxyController.onListen = () {
      //Subscribe to the live stream IMMEDIATELY to avoid missing events.
      final liveSubscription = _singleReplayController!.stream.listen(
        proxyController.add,
        onError: proxyController.addError,
        onDone: proxyController.close,
      )
        // PAUSE the live subscription. Ensures that if new events arrive they are held.
        ..pause();

      // Check the flag. If the buffer hasn't been consumed yet, it belongs to this listener.
      if (!_isFlushed && _noListenValues.isNotEmpty) {
        // Send data directly to the proxy (private).
        for (final event in _noListenValues) {
          proxyController.add(event);
        }
        _noListenValues.clear();
        _isFlushed = true;
      }

      // History is sent.
      liveSubscription.resume();

      //If the user cancels their subscription, cancel the internal connection.
      proxyController.onCancel = () {
        liveSubscription.cancel();
        if (!_singleReplayController!.hasListener) {
          _isFlushed = false;
        }
      };
    };

    return proxyController.stream;
  }

  /// Adds a new event to the service.
  ///
  /// If the stream has an active listener, the event is added directly.
  /// If there are no active listeners, the event is stored in the buffer.
  void add(T event) {
    if (_singleReplayController?.isClosed ?? true) {
      return;
    }

    if (_singleReplayController!.hasListener) {
      _singleReplayController!.add(event);
    } else {
      if (maxBufferSize != null && _noListenValues.length >= maxBufferSize!) {
        _noListenValues.removeAt(0);
      }
      _noListenValues.add(event);
      _isFlushed = false;
    }
  }

  /// Initializes and starts the service.
  ///
  /// If the stream controller was closed (e.g., after a previous [dispose]),
  /// a new one is created. It then calls [work()] for initial setup.
  @override
  void start() {
    _ensureController();

    work();
  }

  /// Cleans up all resources managed by this service.
  ///
  /// This method first calls [stop] to cease ongoing work and then permanently
  /// closes the underlying [StreamController].
  void dispose() {
    stop();
    _singleReplayController?.close();
    _noListenValues.clear();
    _isFlushed = false;
  }

  void _ensureController() {
    if (_singleReplayController != null && !_singleReplayController!.isClosed) {
      return;
    }
    _singleReplayController = StreamController<T>.broadcast();
    _isFlushed = false;
    _noListenValues.clear();
  }

  /// Stops any ongoing work.
  ///
  /// Concrete implementations must override this to stop specific activities
  /// initiated in [work]. The controller is NOT closed here.
  @override
  void stop() {}
}
