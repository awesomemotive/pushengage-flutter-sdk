class DebugLogger {
  static bool _isLoggingEnabled = false;

  // Enable logging
  static void enableLogging() {
    _isLoggingEnabled = true;
  }

  // Disable logging
  static void disableLogging() {
    _isLoggingEnabled = false;
  }

  // Log message if logging is enabled
  static void log(String message) {
    if (_isLoggingEnabled) {
      print(message);
    }
  }
}
