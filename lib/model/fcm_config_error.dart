/// An FCM configuration error reported by the PushEngage Android SDK.
///
/// Delivered via [PushEngage.onFcmConfigError]. Android only — the stream
/// never emits on iOS.
///
/// Codes:
/// - `5001` — FCM sender id mismatch
/// - `5002` — FCM project id mismatch
/// - `5003` — local FCM config invalid
/// - `5004` — both sender id and project id mismatch
class FcmConfigError {
  /// The error code (e.g. `5001`, `5002`, `5003`, `5004`).
  final int code;

  /// A human-readable description of the configuration problem.
  final String message;

  const FcmConfigError({required this.code, required this.message});

  @override
  String toString() => 'FcmConfigError(code: $code, message: $message)';
}
