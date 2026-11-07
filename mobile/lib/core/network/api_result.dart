/// Typed Result and Network Failure types for strict error handling without silent falls.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;
  bool get isFailure => this is ApiFailure<T>;

  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(data: final d) => d,
        ApiFailure<T>() => null,
      };

  NetworkFailure? get failureOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(failure: final f) => f,
      };
}

final class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  final bool isFromCache;
  final DateTime timestamp;

  const ApiSuccess(
    this.data, {
    this.isFromCache = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _DefaultDateTime();
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}

final class ApiFailure<T> extends ApiResult<T> {
  final NetworkFailure failure;

  const ApiFailure(this.failure);
}

final class NetworkFailure {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? validationErrors;
  final bool isNetworkError;
  final bool isUnauthorized;

  const NetworkFailure({
    required this.message,
    this.statusCode,
    this.validationErrors,
    this.isNetworkError = false,
    this.isUnauthorized = false,
  });

  @override
  String toString() => 'NetworkFailure(status: $statusCode, message: $message)';
}

