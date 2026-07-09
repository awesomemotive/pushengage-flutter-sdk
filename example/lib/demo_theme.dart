import 'package:flutter/material.dart';

/// The demo's colour palette, mirroring the RN example app.
class DemoColors {
  DemoColors._();

  static const Color primary = Color(0xFF224ADB); // body buttons / OK / links
  static const Color header = Color(0xFF4040FF); // nav bar
  static const Color screenBg = Color(0xFFF5F5F7);
  static const Color success = Color(0xFF1A7F37);
  static const Color successDark = Color(0xFF7BE07B); // event-log success line
  static const Color error = Color(0xFFB00020);
  static const Color errorDark = Color(0xFFFF8888); // event-log error line
  static const Color destructive = Color(0xFFDB2222);
  static const Color stagingChip = Color(0xFF6750A4);
  static const Color productionChip = Color(0xFF1A7F37);
  static const Color logBg = Color(0xFF1E1E1E);
  static const Color logHeader = Color(0xFF2A2A2A);
  static const Color border = Color(0xFFDDDDDD);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color track = Color(0xFFE5E5EA);
  static const Color placeholder = Color(0xFF999999);
  static const Color secondary = Color(0xFF666666);
  static const Color chevron = Color(0xFFC7C7CC);
}

/// Monospace family for code/JSON/app-id display (Courier on iOS, monospace on
/// Android via Flutter's generic family handling).
const String kMonospace = 'monospace';

/// Two-digit zero-padded `HH:MM:SS` for event-log timestamps.
String formatLogTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
