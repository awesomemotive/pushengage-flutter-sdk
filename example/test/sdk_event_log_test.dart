import 'package:flutter_test/flutter_test.dart';
import 'package:pushengage_flutter_sdk_example/sdk_event_log.dart';

void main() {
  setUp(() => SdkEventLog.instance.clear());

  test('newest event is first', () {
    SdkEventLog.instance.info('first');
    SdkEventLog.instance.success('second');
    expect(SdkEventLog.instance.events.first.title, 'second');
    expect(SdkEventLog.instance.events.first.level, SdkEventLevel.success);
  });

  test('caps at 50 newest-first', () {
    for (var i = 0; i < 60; i++) {
      SdkEventLog.instance.info('e$i');
    }
    expect(SdkEventLog.instance.events.length, 50);
    expect(SdkEventLog.instance.events.first.title, 'e59');
    expect(SdkEventLog.instance.events.last.title, 'e10');
  });

  test('records level and detail', () {
    SdkEventLog.instance.error('boom', 'stack');
    final e = SdkEventLog.instance.events.first;
    expect(e.level, SdkEventLevel.error);
    expect(e.title, 'boom');
    expect(e.detail, 'stack');
  });

  test('clear empties the log', () {
    SdkEventLog.instance.info('x');
    SdkEventLog.instance.clear();
    expect(SdkEventLog.instance.events, isEmpty);
  });

  test('notifies listeners on log and clear', () {
    var count = 0;
    void listener() => count++;
    SdkEventLog.instance.addListener(listener);
    SdkEventLog.instance.info('a');
    SdkEventLog.instance.clear();
    SdkEventLog.instance.removeListener(listener);
    expect(count, 2);
  });
}
