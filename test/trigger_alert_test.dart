import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/model/trigger_alert.dart';

void main() {
  test('toMap emits UTC ISO-8601 with fractional seconds and Z', () {
    final local = DateTime(2026, 6, 9, 12, 0, 0);
    final m = TriggerAlert(
      type: TriggerAlertType.priceDrop,
      productId: 'p',
      link: 'l',
      price: 1.0,
      expiryTimestamp: local,
    ).toMap();

    final ts = m['expiryTimestamp'] as String;
    expect(ts.endsWith('Z'), true, reason: 'must carry a timezone designator');
    expect(RegExp(r'\.\d{3}Z$').hasMatch(ts), true,
        reason: 'must carry fractional seconds');
    expect(DateTime.parse(ts), local.toUtc());
  });

  test('toMap maps enum names to wire strings', () {
    final m = TriggerAlert(
      type: TriggerAlertType.inventory,
      productId: 'p',
      link: 'l',
      price: 1.0,
      availability: TriggerAlertAvailabilityType.outOfStock,
    ).toMap();
    expect(m['type'], 'inventory');
    expect(m['availability'], 'outOfStock');
  });

  test('toMap truncates sub-millisecond precision for Android parser', () {
    // DateTime with microseconds — toIso8601String would emit 6 fractional
    // digits, which Android's SimpleDateFormat(".SSS") rejects.
    final withMicros = DateTime.utc(2026, 6, 9, 12, 0, 0, 123, 456);
    final m = TriggerAlert(
      type: TriggerAlertType.priceDrop,
      productId: 'p',
      link: 'l',
      price: 1.0,
      expiryTimestamp: withMicros,
    ).toMap();

    final ts = m['expiryTimestamp'] as String;
    expect(
        RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$').hasMatch(ts),
        true,
        reason: 'must be exactly 3 fractional digits, got: $ts');
    expect(ts, '2026-06-09T12:00:00.123Z');
  });

  test('toMap leaves expiryTimestamp null when absent', () {
    final m = TriggerAlert(
      type: TriggerAlertType.priceDrop,
      productId: 'p',
      link: 'l',
      price: 1.0,
    ).toMap();
    expect(m['expiryTimestamp'], isNull);
  });
}
