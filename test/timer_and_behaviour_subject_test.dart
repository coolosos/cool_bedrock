import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'service_mock/behavior/timer_and_behavior_subject_mock.dart';

void main() {
  const duration = Duration(seconds: 10);

  group('TimerAndBehaviorService Tests', () {
    test('should execute work periodically and update stream', () {
      fakeAsync((async) {
        final service = MockTimerService(periodicDuration: duration);
        final results = <int>[];

        service.start();

        service.stream?.listen(results.add);

        async.elapse(duration);
        expect(results, [1], reason: 'Should have fired once after 10s');

        async.elapse(duration * 2);
        expect(results, [1, 2, 3], reason: 'Should have fired 3 times total');

        service.dispose();
      });
    });

    test('should stop timer when stop() is called', () {
      fakeAsync((async) {
        final service = MockTimerService(periodicDuration: duration);
        final results = <int>[];

        service.start();
        service.stream?.listen(results.add);

        async.elapse(duration);
        service.stop();

        async.elapse(duration * 5);

        expect(results, [1], reason: 'Should not have fired after stop()');
        service.dispose();
      });
    });

    test('should not duplicate timer if start() is called twice', () {
      fakeAsync((async) {
        final service = MockTimerService(periodicDuration: duration)
          ..start()
          ..start();

        final results = <int>[];
        service.stream?.listen(results.add);

        async.elapse(duration);

        expect(results.length, 1);
        service.dispose();
      });
    });
  });
}
