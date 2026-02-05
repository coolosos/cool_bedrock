import 'package:cool_bedrock/cool_bedrock.dart';

final class MockPublishService extends PublishSubjectService<String> {
  bool workCalled = false;

  @override
  Future<void> work() async {
    workCalled = true;
  }
}
