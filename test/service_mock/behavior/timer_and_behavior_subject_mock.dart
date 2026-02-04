import 'package:cool_bedrock/cool_bedrock.dart';

final class MockTimerService extends TimerAndBehaviorService<int> {
  MockTimerService({required super.periodicDuration});

  int counter = 0;

  @override
  Future<void> work() async {
    counter++;
    add(counter);
  }
}
