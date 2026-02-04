import 'package:cool_bedrock/cool_bedrock.dart';

final class MockSingleReplayMaxBuffer
    extends SingleReplaySubjectService<String> {
  MockSingleReplayMaxBuffer({super.maxBufferSize = 2});
  @override
  Future<void> work() async {}
}
