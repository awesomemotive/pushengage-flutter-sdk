import 'package:flutter/foundation.dart';

/// Severity of an [SdkEvent], driving its colour in the event-log panel.
enum SdkEventLevel { info, success, error }

/// A single entry in the in-memory [SdkEventLog].
class SdkEvent {
  final int id;
  final DateTime timestamp;
  final SdkEventLevel level;
  final String title;
  final String? detail;

  SdkEvent({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.title,
    this.detail,
  });
}

/// A singleton, observable, in-memory log (newest-first, capped) that the home
/// screen subscribes to. Mirrors the native/RN demos' SdkEventLog.
class SdkEventLog extends ChangeNotifier {
  SdkEventLog._();

  /// The shared instance used across the demo.
  static final SdkEventLog instance = SdkEventLog._();

  /// Maximum retained events; older entries are dropped.
  static const int maxEvents = 50;

  final List<SdkEvent> _events = [];
  int _nextId = 1;

  /// The current events, newest first (unmodifiable snapshot).
  List<SdkEvent> get events => List.unmodifiable(_events);

  /// Appends an event (prepended so the newest is first) and trims to
  /// [maxEvents].
  void log(SdkEventLevel level, String title, [String? detail]) {
    _events.insert(
      0,
      SdkEvent(
        id: _nextId++,
        timestamp: DateTime.now(),
        level: level,
        title: title,
        detail: detail,
      ),
    );
    if (_events.length > maxEvents) {
      _events.removeRange(maxEvents, _events.length);
    }
    notifyListeners();
  }

  void info(String title, [String? detail]) =>
      log(SdkEventLevel.info, title, detail);

  void success(String title, [String? detail]) =>
      log(SdkEventLevel.success, title, detail);

  void error(String title, [String? detail]) =>
      log(SdkEventLevel.error, title, detail);

  /// Empties the log.
  void clear() {
    _events.clear();
    notifyListeners();
  }
}
