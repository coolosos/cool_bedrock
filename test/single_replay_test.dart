// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'service_mock/single_replay/single_replay_max_buffer_mock.dart';
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

  group('SingleReplaySubjectMaxBufferService', () {
    late MockSingleReplayMaxBuffer service;

    setUp(() {
      service = MockSingleReplayMaxBuffer(maxBufferSize: 2);
      service.start();
    });
    test('Should add event directly to stream when there is a listener',
        () async {
      final events = <String>[];

      service.stream.listen(events.add);

      await Future.delayed(Duration.zero);

      service.add('event 1');

      await Future.delayed(Duration.zero);

      expect(events, contains('event 1'));
      expect(events, hasLength(1));
    });

    test('Should buffer events and respect maxBufferSize when no listener', () {
      // No nos suscribimos -> hasListener es false

      service.add('event 1');
      service.add('event 2');
      service.add(
        'event 3',
      );

      service.stream.listen(
        expectAsync1(
          (event) {},
          count: 2,
        ),
      );
    });

    test('Should reset _isFlushed to false when adding to buffer', () async {
      // 1. Flush inicial
      service.add('event 1');
      final sub = service.stream.listen((_) {});
      await Future.microtask(() {});

      await sub.cancel();

      service.add('event 2');

      service.stream.listen(
        expectAsync1((event) {
          expect(event, equals('event 2'));
        }),
      );
    });
  });
}
