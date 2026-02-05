import 'package:cool_bedrock/cool_bedrock.dart';

final class BehaviorServiceMock extends BehaviorSubjectService<int> {
  bool workCalled = false;
  bool stopCalled = false;

  @override
  Future<void> work() async {
    workCalled = true;
    // Initial event
    add(1);
  }

  @override
  void stop() {
    stopCalled = true;
    super.stop();
  }
}
