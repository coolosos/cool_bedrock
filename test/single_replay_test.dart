// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'service_mock/single_replay/single_replay_mock.dart';

void main() {
  group('SingleReplaySubjectService Tests', () {
    late MockSingleReplayService service;

    setUp(() {
      service = MockSingleReplayService();
    });

    test('should flush buffered events ONLY to the first subscriber', () async {
      service.start();

      final firstResultsExpectation = expectLater(
        service.stream,
        emitsInOrder(['Init Event 1', 'Init Event 2', 'Live Event']),
      );

      final secondResults = <String>[];

      await Future.delayed(Duration.zero);

      final sub2 = service.stream.listen(secondResults.add);

      service.add('Live Event');

      await firstResultsExpectation;

      expect(secondResults, ['Live Event']);
      expect(secondResults, isNot(contains('Init Event 1')));

      await sub2.cancel();
    });
    test('should buffer events added manually when no listener is present',
        () async {
      service.start();
      service.add('Manual Buffer');

      final results = <String>[];
      await service.stream.first.then(results.add);

      expect(results, contains('Init Event 1'));
    });

    test('should clean up and close controller on dispose', () async {
      service.start();
      var isDone = false;

      service.stream.listen((_) {}, onDone: () => isDone = true);

      await Future.delayed(Duration.zero);

      service.dispose();

      await Future.delayed(Duration.zero);

      expect(isDone, isTrue, reason: 'StreamController should be closed');
    });
  });
}
