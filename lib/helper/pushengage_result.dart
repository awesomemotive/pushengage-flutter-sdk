enum PushEngageResultStatus { success, failure }

class PushEngageResult<T> {
  final T? data;
  final Object? error;
  final PushEngageResultStatus status;

  PushEngageResult._({this.data, this.error, required this.status});

  factory PushEngageResult.success(T data) {
    return PushEngageResult._(
        data: data, error: null, status: PushEngageResultStatus.success);
  }

  factory PushEngageResult.failure(Object error) {
    return PushEngageResult._(
        data: null, error: error, status: PushEngageResultStatus.failure);
  }

  bool get isSuccess => status == PushEngageResultStatus.success;
}
