import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('PushEngage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('toMap emits only set fields with snake_case keys', () {
    expect(IdentifyFields(email: 'a@b.com', profileId: 'u1').toMap(),
        {'email': 'a@b.com', 'profile_id': 'u1'});
  });

  test('toMap is empty when nothing is set', () {
    expect(IdentifyFields().toMap(), <String, dynamic>{});
  });

  test('identify forwards encoded fields and returns success', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      return 'Identify successful';
    });

    final res = await PushEngage.identify(
        IdentifyFields(firstName: 'A', email: 'a@b.com'));

    expect(res.isSuccess, true);
    expect(calls.single.method, 'PushEngage#identify');
    final fields =
        jsonDecode((calls.single.arguments as Map)['fields'] as String);
    expect(fields, {'first_name': 'A', 'email': 'a@b.com'});
  });

  test('identify maps a PlatformException to failure', () async {
    messenger.setMockMethodCallHandler(channel, (c) async {
      throw PlatformException(code: 'IDENTIFY_ERROR', message: 'boom');
    });
    final res = await PushEngage.identify(IdentifyFields(email: 'a@b.com'));
    expect(res.isSuccess, false);
  });
}
