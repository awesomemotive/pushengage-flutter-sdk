import 'package:pushengage_flutter_sdk/interface/mappable.dart';

/// The 12 predefined subscriber identification fields (Web SDK parity).
///
/// Only the fields you set are sent; unset (null) fields are omitted. Values
/// may be a [String], [num], or [bool]. Passed to [PushEngage.identify].
class IdentifyFields implements Mappable {
  final Object? firstName;
  final Object? lastName;
  final Object? email;
  final Object? phone;
  final Object? gender;
  final Object? dob;
  final Object? language;
  final Object? profileId;
  final Object? country;
  final Object? city;
  final Object? state;
  final Object? zip;

  IdentifyFields({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.dob,
    this.language,
    this.profileId,
    this.country,
    this.city,
    this.state,
    this.zip,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    void put(String key, Object? value) {
      if (value != null) map[key] = value;
    }

    put('first_name', firstName);
    put('last_name', lastName);
    put('email', email);
    put('phone', phone);
    put('gender', gender);
    put('dob', dob);
    put('language', language);
    put('profile_id', profileId);
    put('country', country);
    put('city', city);
    put('state', state);
    put('zip', zip);
    return map;
  }
}
