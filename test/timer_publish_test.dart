// ignore_for_file: cascade_invocations

import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'service_mock/publish/timer_publish_service_mock.dart';

void main() {
  const duration = Duration(seconds: 5);

  group('TimerAndPublishService Tests', () {
    test('should emit periodic events only to active subscribers', () {
      fakeAsync((async) {
        final service = MockTimerPublishService(periodicDuration: duration);
        final results = <String>[];

        service.start();

        async.elapse(duration);

        service.stream?.listen(results.add);

        async.elapse(duration * 2);

        expect(results, ['Tick', 'Tick']);
        expect(results.length, 2);

        service.dispose();
      });
    });

    test('should stop emitting when stop() is called but keep subject open',
        () {
      fakeAsync((async) {
        final service = MockTimerPublishService(periodicDuration: duration);
        final results = <String>[];

        service.start();
        service.stream?.listen(results.add);

        async.elapse(duration);
        service.stop();

        service.add('Manual Event');
        async.elapse(duration * 3);

        expect(results, ['Tick', 'Manual Event']);
        service.dispose();
      });
    });
  });
}
