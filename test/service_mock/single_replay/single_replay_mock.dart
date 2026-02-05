import 'package:cool_bedrock/cool_bedrock.dart';

final class MockSingleReplayService extends SingleReplaySubjectService<String> {
  @override
  Future<void> work() async {
    add('Init Event 1');
    add('Init Event 2');
  }
}
