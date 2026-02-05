import 'package:test/test.dart';

import 'service_mock/publish/publish_subject_mock.dart';

void main() {
  late MockPublishService service;

  setUp(() {
    service = MockPublishService();
  });

  group('PublishSubjectService Tests', () {
    test('should NOT replay events emitted before subscription', () async {
      await service.start();

      service.add('Lost Event');

      final results = <String>[];
      final subscription = service.stream?.listen(results.add);

      service.add('Caught Event');

      await Future.delayed(Duration.zero);

      expect(results, ['Caught Event']);
      expect(results, isNot(contains('Lost Event')));

      await subscription?.cancel();
    });

    test('should broadcast events to multiple listeners', () async {
      await service.start();

      final results1 = <String>[];
      final results2 = <String>[];

      service.stream?.listen(results1.add);
      service.stream?.listen(results2.add);

      service.add('Hello');

      await Future.delayed(Duration.zero);

      expect(results1, ['Hello']);
      expect(results2, ['Hello']);
    });

    test('should allow restarting after stop()', () async {
      await service.start();
      service.stop();

      final results = <String>[];
      service.stream?.listen(results.add);

      service.add('After Stop');
      await Future.delayed(Duration.zero);

      expect(results, ['After Stop']);
    });

    test('should not add events if disposed', () async {
      await service.start();
      service.dispose();

      expect(() => service.add('Dead Event'), returnsNormally);
    });
  });
}
