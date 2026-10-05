import 'package:cool_bedrock/cool_bedrock.dart';

final class MockTimerPublishService extends TimerAndPublishService<String> {
  new({required super.periodicDuration});

  @override
  Future<void> work() async {
    add('Tick');
  }
}
