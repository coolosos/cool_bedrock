import 'package:cool_bedrock/cool_bedrock.dart';

/// Fails on the first tick and succeeds afterwards.
final class FailingTimerService extends TimerAndBehaviorService<int> {
  new({required super.periodicDuration});

  int calls = 0;

  @override
  Future<void> work() async {
    calls++;
    if (calls == 1) {
      throw StateError('Work failed');
    }
    add(calls);
  }
}

/// Same as [FailingTimerService] but for the publish flavour.
final class FailingTimerPublishService extends TimerAndPublishService<String> {
  new({required super.periodicDuration});

  int calls = 0;

  @override
  Future<void> work() async {
    calls++;
    if (calls == 1) {
      throw StateError('Work failed');
    }
    add('Tick $calls');
  }
}
