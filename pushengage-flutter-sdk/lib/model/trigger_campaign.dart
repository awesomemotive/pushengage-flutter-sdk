import 'package:pushengage_flutter_sdk/interface/mappable.dart';

class TriggerCampaign implements Mappable {
  final String campaignName;
  final String eventName;
  String? referenceId;
  String? profileId;
  Map<String, String>? data;

  TriggerCampaign({
    required this.campaignName,
    required this.eventName,
    this.referenceId,
    this.profileId,
    this.data,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'campaignName': campaignName,
      'eventName': eventName,
      'referenceId': referenceId,
      'profileId': profileId,
      'data': data,
    };
  }
}

enum TriggerStatusType { enabled, disabled }
