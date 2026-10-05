// ignore_for_file: cascade_invocations Test visibility

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'service_mock/behavior/behavior_subject_mock.dart';
import 'service_mock/behavior/timer_and_behavior_subject_mock.dart';
import 'service_mock/behavior/timer_failing_subject_mock.dart';
import 'service_mock/publish/publish_subject_mock.dart';
import 'service_mock/publish/timer_publish_service_mock.dart';
import 'service_mock/single_replay/single_replay_mock.dart';

void main() {
  const duration = Duration(seconds: 10);

  group('add before start', () {
    test(
      'BehaviorSubjectService should drop events added before start',
      () async {
        final service = BehaviorServiceMock();
        service.add(999);

        service.start();

        expect(await service.stream?.first, equals(1));
      },
    );

    test(
      'PublishSubjectService should drop events added before start',
      () async {
        final service = MockPublishService();
        service.add('early');

        await service.start();

        final events = <String>[];
        service.stream?.listen(events.add);
        service.add('late');

        await Future<void>.delayed(Duration.zero);

        expect(events, isNot(contains('early')));
        expect(events, contains('late'));
      },
    );

    test(
      'SingleReplaySubjectService should drop events added before start',
      () async {
        final service = MockSingleReplayService();
        service.add('early');

        service.start();

        final events = <String>[];
        service.stream.listen(events.add);

        await Future<void>.delayed(Duration.zero);

        expect(events, isNot(contains('early')));
        expect(events, contains('Init Event 1'));
      },
    );
  });

  group('restart after dispose', () {
    test(
      'BehaviorSubjectService should create a new subject on start',
      () async {
        final service = BehaviorServiceMock();
        service.start();
        expect(await service.stream?.first, equals(1));

        service.dispose();
        service.start();

        expect(await service.stream?.first, equals(1));
      },
    );

    test(
      'PublishSubjectService should create a new subject on start',
      () async {
        final service = MockPublishService();
        await service.start();
        service.dispose();
        await service.start();

        final events = <String>[];
        service.stream?.listen(events.add);
        service.add('after restart');

        await Future<void>.delayed(Duration.zero);

        expect(events, contains('after restart'));
      },
    );

    test(
      'SingleReplaySubjectService should create a new controller on start',
      () async {
        final service = MockSingleReplayService();
        service.start();
        service.dispose();
        service.start();

        final events = <String>[];
        service.stream.listen(events.add);

        await Future<void>.delayed(Duration.zero);

        expect(events, containsAll(['Init Event 1', 'Init Event 2']));
      },
    );

    test('TimerAndBehaviorService should create a new subject and timer', () {
      fakeAsync((async) {
        final service = MockTimerService(periodicDuration: duration);
        final results = <int>[];

        service.start();
        service.stream?.listen(results.add);
        async.elapse(duration);
        expect(results, [1]);

        service.dispose();
        async.elapse(duration * 3);
        expect(results, [1], reason: 'dispose must stop the timer');

        service.start();
        service.stream?.listen(results.add);
        async.elapse(duration);
        expect(results, [1, 2], reason: 'the restarted service ticks again');

        service.dispose();
      });
    });

    test('TimerAndPublishService should create a new subject and timer', () {
      fakeAsync((async) {
        final service = MockTimerPublishService(periodicDuration: duration);
        final results = <String>[];

        service.start();
        service.stream?.listen(results.add);
        async.elapse(duration);
        expect(results, ['Tick']);

        service.dispose();
        async.elapse(duration * 3);
        expect(results, ['Tick'], reason: 'dispose must stop the timer');

        service.start();
        service.stream?.listen(results.add);
        async.elapse(duration);
        expect(results, ['Tick', 'Tick']);

        service.dispose();
      });
    });
  });

  group('dispose', () {
    test(
      'TimerAndBehaviorService should stop ticking and close the subject',
      () {
        fakeAsync((async) {
          final service = MockTimerService(periodicDuration: duration);
          final results = <int>[];

          service.start();
          service.stream?.listen(results.add);
          async.elapse(duration);

          service.dispose();
          service.add(42);
          async.elapse(duration * 3);

          expect(results, [
            1,
          ], reason: 'neither the timer nor the subject alive');

          service.start();
          service.add(7);
          async.elapse(duration);

          expect(results, [1], reason: 'add must be ignored while disposed');

          service.dispose();
        });
      },
    );

    test(
      'TimerAndPublishService should stop ticking and close the subject',
      () {
        fakeAsync((async) {
          final service = MockTimerPublishService(periodicDuration: duration);
          final results = <String>[];

          service.start();
          service.stream?.listen(results.add);
          async.elapse(duration);

          service.dispose();
          service.add('manual');
          async.elapse(duration * 3);

          expect(results, ['Tick']);

          service.dispose();
        });
      },
    );

    test(
      'SingleReplaySubjectService should ignore events added after dispose',
      () async {
        final service = MockSingleReplayService();
        service.start();
        service.dispose();

        expect(() => service.add('after dispose'), returnsNormally);

        final events = <String>[];
        service.stream.listen(events.add);
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);
      },
    );
  });

  group('failing work', () {
    test(
      'TimerAndBehaviorService should let a failing work() reach the zone',
      () {
        final errors = <Object>[];

        runZonedGuarded(() {
          fakeAsync((async) {
            final service = FailingTimerService(periodicDuration: duration);
            final results = <int>[];

            service.start();
            service.stream?.listen(results.add);

            async.elapse(duration);
            async.elapse(duration);

            expect(
              service.calls,
              equals(2),
              reason: 'the timer keeps firing after a failing work()',
            );
            expect(results, [2], reason: 'only the successful tick emits');
            service.dispose();
          });
        }, (error, stack) => errors.add(error));

        expect(
          errors,
          hasLength(1),
          reason: 'the periodic work is not wrapped, so the error is unhandled',
        );
        expect(errors.single, isA<StateError>());
      },
    );

    test(
      'TimerAndPublishService should let a failing work() reach the zone',
      () {
        final errors = <Object>[];

        runZonedGuarded(() {
          fakeAsync((async) {
            final service = FailingTimerPublishService(
              periodicDuration: duration,
            );
            final results = <String>[];

            service.start();
            service.stream?.listen(results.add);

            async.elapse(duration);
            async.elapse(duration);

            expect(service.calls, equals(2));
            expect(results, ['Tick 2']);
            service.dispose();
          });
        }, (error, stack) => errors.add(error));

        expect(errors, hasLength(1));
        expect(errors.single, isA<StateError>());
      },
    );
  });
}
