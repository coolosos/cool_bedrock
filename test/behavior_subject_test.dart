// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'service_mock/behavior/behavior_subject_mock.dart';

void main() {
  late BehaviorServiceMock service;

  setUp(() {
    service = BehaviorServiceMock();
  });

  group('BehaviorSubjectService Tests', () {
    test('should initialize subject and call work() on start', () async {
      expect(service.workCalled, isFalse);

      service.start();

      expect(service.workCalled, isTrue);

      expect(await service.stream?.first, equals(1));
    });

    test('should broadcast multiple values via add()', () async {
      service.start();

      final results = <int>[];
      final subscription = service.stream?.listen(results.add);

      service.add(10);
      service.add(20);

      await Future.delayed(Duration.zero);

      expect(results, containsAll([1, 10, 20]));
      await subscription?.cancel();
    });

    test('should allow restarting after stop() without closing subject',
        () async {
      service.start();
      service.add(100);

      service.stop();
      expect(service.stopCalled, isTrue);

      final nextValue = service.stream?.skip(1).first;

      service.add(200);

      expect(await nextValue, equals(200));
    });

    test('should permanently close subject on dispose()', () async {
      service.start();
      service.dispose();

      service.add(500);

      expect(service.stopCalled, isTrue);
    });
  });
}
