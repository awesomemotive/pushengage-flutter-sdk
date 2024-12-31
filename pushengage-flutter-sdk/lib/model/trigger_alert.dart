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

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'productId': productId,
      'link': link,
      'price': price,
      'variantId': variantId,
      'expiryTimestamp': expiryTimestamp?.toIso8601String(),
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
      default:
        return '';
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
      default:
        return '';
    }
  }
}
