import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/helper/pushengage_result.dart';

void main() {
  group('PushEngageResult', () {
    test('success holds data, no error, isSuccess true', () {
      final r = PushEngageResult.success(42);
      expect(r.isSuccess, true);
      expect(r.status, PushEngageResultStatus.success);
      expect(r.data, 42);
      expect(r.error, isNull);
    });

    test('success supports a nullable payload', () {
      final r = PushEngageResult<String?>.success(null);
      expect(r.isSuccess, true);
      expect(r.data, isNull);
    });

    test('failure holds error, no data, isSuccess false', () {
      final r = PushEngageResult.failure('boom');
      expect(r.isSuccess, false);
      expect(r.status, PushEngageResultStatus.failure);
      expect(r.error, 'boom');
      expect(r.data, isNull);
    });
  });
}
