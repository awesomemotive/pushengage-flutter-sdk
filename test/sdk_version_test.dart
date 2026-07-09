import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';

void main() {
  test('getSdkVersion matches the pubspec.yaml version', () {
    // Derived (not pinned) so the release script's version bump cannot strand
    // a stale literal here and abort the release at the flutter-test gate.
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final versionLine =
        pubspec.firstWhere((line) => line.startsWith('version:'));
    final version = versionLine.split(':').last.trim();
    expect(PushEngage.getSdkVersion(), version);
  });
}
