import 'package:pushengage_flutter_sdk/interface/mappable.dart';

class DynamicSegment implements Mappable {
  final String name;
  final int duration;

  DynamicSegment({required this.name, required this.duration});

  Map<String, dynamic> toMap() => {
        'name': name,
        'duration': duration,
      };
}
