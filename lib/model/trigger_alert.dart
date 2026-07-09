class TriggerAlert {
  final TriggerAlertType type;
  final String productId;
  final String link;
  final double price;
  final String? variantId;
  final DateTime? expiryTimestamp;
  final double? alertPrice;
  final TriggerAlertAvailabilityType? availability;
  final String? profileId;
  final double? mrp;
  final Map<String, String>? data;

  TriggerAlert({
    required this.type,
    required this.productId,
    required this.link,
    required this.price,
    this.variantId,
    this.expiryTimestamp,
    this.alertPrice,
    this.availability,
    this.profileId,
    this.mrp,
    this.data,
  });

  // Android's SimpleDateFormat("...HH:mm:ss.SSSXXX") accepts exactly 3
  // fractional digits; Dart's toIso8601String emits 6 when microseconds are
  // non-zero. Truncate to millisecond precision before formatting.
  static String? _formatExpiryTimestamp(DateTime? ts) {
    if (ts == null) return null;
    final utc = ts.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute,
            utc.second, utc.millisecond)
        .toIso8601String();
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'productId': productId,
      'link': link,
      'price': price,
      'variantId': variantId,
      'expiryTimestamp': _formatExpiryTimestamp(expiryTimestamp),
      'alertPrice': alertPrice,
      'availability': availability?.name,
      'profileId': profileId,
      'mrp': mrp,
      'data': data,
    };
  }
}

enum TriggerAlertType {
  priceDrop,
  inventory,
}

extension TriggerAlertTypeExtension on TriggerAlertType {
  String get name {
    switch (this) {
      case TriggerAlertType.priceDrop:
        return 'priceDrop';
      case TriggerAlertType.inventory:
        return 'inventory';
    }
  }
}

enum TriggerAlertAvailabilityType {
  inStock,
  outOfStock,
}

extension TriggerAlertAvailabilityTypeExtension
    on TriggerAlertAvailabilityType {
  String get name {
    switch (this) {
      case TriggerAlertAvailabilityType.inStock:
        return 'inStock';
      case TriggerAlertAvailabilityType.outOfStock:
        return 'outOfStock';
    }
  }
}
