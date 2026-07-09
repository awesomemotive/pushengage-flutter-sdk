import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/model/goal.dart';
import 'package:pushengage_flutter_sdk/model/dynamic_segment.dart';
import 'package:pushengage_flutter_sdk/model/trigger_campaign.dart';
import 'package:pushengage_flutter_sdk/model/trigger_alert.dart';

void main() {
  group('Goal.toMap', () {
    test('includes name, count and value', () {
      expect(Goal(name: 'g', count: 2, value: 1.5).toMap(),
          {'name': 'g', 'count': 2, 'value': 1.5});
    });

    test('null count/value pass through as null', () {
      expect(
          Goal(name: 'g').toMap(), {'name': 'g', 'count': null, 'value': null});
    });
  });

  group('DynamicSegment.toMap', () {
    test('includes name and duration', () {
      expect(DynamicSegment(name: 'sports', duration: 5).toMap(),
          {'name': 'sports', 'duration': 5});
    });
  });

  group('TriggerCampaign.toMap', () {
    test('includes all fields', () {
      expect(
        TriggerCampaign(
          campaignName: 'c',
          eventName: 'e',
          referenceId: 'r',
          profileId: 'p',
          data: {'k': 'v'},
        ).toMap(),
        {
          'campaignName': 'c',
          'eventName': 'e',
          'referenceId': 'r',
          'profileId': 'p',
          'data': {'k': 'v'},
        },
      );
    });

    test('optional fields are null when omitted', () {
      final m = TriggerCampaign(campaignName: 'c', eventName: 'e').toMap();
      expect(m['referenceId'], isNull);
      expect(m['profileId'], isNull);
      expect(m['data'], isNull);
    });
  });

  group('TriggerStatusType', () {
    test('enum has enabled and disabled', () {
      expect(TriggerStatusType.values, [
        TriggerStatusType.enabled,
        TriggerStatusType.disabled,
      ]);
    });
  });

  group('TriggerAlert.toMap full round-trip', () {
    test('serializes every field with wire-format values', () {
      final m = TriggerAlert(
        type: TriggerAlertType.priceDrop,
        productId: 'p1',
        link: 'https://example.com/p1',
        price: 9.99,
        variantId: 'v1',
        expiryTimestamp: DateTime.utc(2026, 6, 9, 12),
        alertPrice: 7.99,
        availability: TriggerAlertAvailabilityType.inStock,
        profileId: 'u1',
        mrp: 12.0,
        data: {'k': 'v'},
      ).toMap();

      expect(m['type'], 'priceDrop');
      expect(m['productId'], 'p1');
      expect(m['link'], 'https://example.com/p1');
      expect(m['price'], 9.99);
      expect(m['variantId'], 'v1');
      expect(m['expiryTimestamp'], '2026-06-09T12:00:00.000Z');
      expect(m['alertPrice'], 7.99);
      expect(m['availability'], 'inStock');
      expect(m['profileId'], 'u1');
      expect(m['mrp'], 12.0);
      expect(m['data'], {'k': 'v'});
    });

    test('inventory type and outOfStock availability map to wire strings', () {
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

    test('optional fields are null when omitted', () {
      final m = TriggerAlert(
        type: TriggerAlertType.priceDrop,
        productId: 'p',
        link: 'l',
        price: 1.0,
      ).toMap();
      expect(m['variantId'], isNull);
      expect(m['expiryTimestamp'], isNull);
      expect(m['alertPrice'], isNull);
      expect(m['availability'], isNull);
      expect(m['profileId'], isNull);
      expect(m['mrp'], isNull);
      expect(m['data'], isNull);
    });
  });
}
