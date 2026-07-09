import 'package:pushengage_flutter_sdk/interface/mappable.dart';

/// A custom analytics event for [PushEngage.trackEvent].
///
/// [eventName] is required and must be non-empty. [provider] and [eventType]
/// default to `"PushEngage"` and `"PushEngage.CustomEvent"` in the native SDK
/// when omitted. Unset optional fields are not sent.
class TrackEventPayload implements Mappable {
  final String eventName;
  final Map<String, Object>? data;
  final String? profileId;
  final String? provider;
  final String? eventType;

  TrackEventPayload({
    required this.eventName,
    this.data,
    this.profileId,
    this.provider,
    this.eventType,
  });

  @override
  Map<String, dynamic> toMap() {
    if (eventName.isEmpty) {
      throw ArgumentError('TrackEventPayload.eventName must not be empty');
    }
    final map = <String, dynamic>{'eventName': eventName};
    if (data != null) map['data'] = data;
    if (profileId != null) map['profileId'] = profileId;
    if (provider != null) map['provider'] = provider;
    if (eventType != null) map['eventType'] = eventType;
    return map;
  }
}
