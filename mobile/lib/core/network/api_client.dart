import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_result.dart';

/// Industrial HTTP Client wrapper for Zolo ERP Mobile.
class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;
  final Uuid _uuid = const Uuid();
  Future<bool>? _inFlightFailover;
  DateTime? _lastFailoverFailureAt;

  ApiClient(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _storage.getServerUrl(),
            connectTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Sanctum Token
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Attach Company, Branch, Financial Year Context
          final companyId = _storage.getActiveCompanyId();
          if (companyId != null) {
            options.headers['X-Company-ID'] = companyId.toString();
          }

          final branchId = _storage.getActiveBranchId();
          if (branchId != null) {
            options.headers['X-Branch-ID'] = branchId.toString();
          }

          final fyId = _storage.getActiveFinancialYearId();
          if (fyId != null) {
            options.headers['X-Financial-Year-ID'] = fyId.toString();
          }

          // Attach Idempotency-Key for safe offline/retried mutations
          if (options.method == 'POST' ||
              options.method == 'PUT' ||
              options.method == 'PATCH') {
            if (!options.headers.containsKey('Idempotency-Key')) {
              options.headers['Idempotency-Key'] = _uuid.v4();
            }
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  String get baseUrl => _dio.options.baseUrl;

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  Future<bool> _tryFailoverServer() async {
    final lastFail = _lastFailoverFailureAt;
    if (lastFail != null &&
        DateTime.now().difference(lastFail) < const Duration(seconds: 25)) {
      return false;
    }
    final existing = _inFlightFailover;
    if (existing != null) {
      return existing;
    }
    final completer = Completer<bool>();
    _inFlightFailover = completer.future;

    unawaited(_probeFailoverCandidates().then((found) {
      if (!found) {
        _lastFailoverFailureAt = DateTime.now();
      } else {
        _lastFailoverFailureAt = null;
      }
      _inFlightFailover = null;
      if (!completer.isCompleted) {
        completer.complete(found);
      }
    }).catchError((_) {
      _lastFailoverFailureAt = DateTime.now();
      _inFlightFailover = null;
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }));

    return completer.future;
  }

  Future<bool> _probeFailoverCandidates() async {
    final current = _dio.options.baseUrl.trim();
    final candidates = ApiEndpoints.fallbackBaseUrls
        .where((candidate) => candidate != current)
        .toList();
    if (candidates.isEmpty) return false;

    final raceCompleter = Completer<bool>();
    var remaining = candidates.length;

    for (final candidate in candidates) {
      unawaited(() async {
        try {
          final probe = Dio(
            BaseOptions(
              baseUrl: candidate,
              connectTimeout: const Duration(milliseconds: 1200),
              receiveTimeout: const Duration(milliseconds: 1200),
              headers: const {'Accept': 'application/json'},
            ),
          );
          final res = await probe.get<dynamic>(ApiEndpoints.ping);
          final code = res.statusCode;
          if (!raceCompleter.isCompleted &&
              code != null &&
              code >= 200 &&
              code < 300) {
            _dio.options.baseUrl = candidate;
            await _storage.setServerUrl(candidate);
            raceCompleter.complete(true);
            return;
          }
        } catch (_) {
          // Candidate unreachable
        }
        remaining--;
        if (remaining <= 0 && !raceCompleter.isCompleted) {
          raceCompleter.complete(false);
        }
      }());
    }

    return raceCompleter.future;
  }

  Future<ApiResult<T>> _execute<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) fromJson,
  ) async {
    try {
      final response = await request();
      final code = response.statusCode;
      if (code != null && code >= 200 && code < 300) {
        return ApiSuccess(fromJson(response.data));
      }
      return ApiFailure(
        NetworkFailure(
          statusCode: code,
          message: 'Server error: $code',
        ),
      );
    } on DioException catch (e) {
      final isConnErr = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;
      if (isConnErr && await _tryFailoverServer()) {
        try {
          final retryResponse = await request();
          final code = retryResponse.statusCode;
          if (code != null && code >= 200 && code < 300) {
            return ApiSuccess(fromJson(retryResponse.data));
          }
        } on DioException catch (retryErr) {
          return ApiFailure(_mapDioError(retryErr));
        } catch (retryErr) {
          return ApiFailure(
            NetworkFailure(message: 'Unexpected client error: $retryErr'),
          );
        }
      }
      return ApiFailure(_mapDioError(e));
    } catch (e) {
      return ApiFailure(
        NetworkFailure(message: 'Unexpected client error: $e'),
      );
    }
  }

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) =>
      _execute(() => _dio.get(path, queryParameters: queryParameters), fromJson);

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) {
    final options = idempotencyKey != null
        ? Options(headers: {'Idempotency-Key': idempotencyKey})
        : null;
    return _execute(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      fromJson,
    );
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) =>
      _execute(
        () => _dio.put(path, data: data, queryParameters: queryParameters),
        fromJson,
      );

  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) =>
      _execute(
        () => _dio.patch(path, data: data, queryParameters: queryParameters),
        fromJson,
      );

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) =>
      _execute(
        () => _dio.delete(path, data: data, queryParameters: queryParameters),
        fromJson,
      );

  NetworkFailure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return NetworkFailure(
        message: 'Network connection failed (${_dio.options.baseUrl}). Operating in offline mode.',
        isNetworkError: true,
      );
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return const NetworkFailure(
        statusCode: 401,
        message: 'Invalid credentials or session expired. Please sign in.',
        isUnauthorized: true,
      );
    }

    if (statusCode == 403) {
      return const NetworkFailure(
        statusCode: 403,
        message: 'Access denied: You do not have permission for this module.',
      );
    }

    if (statusCode == 422) {
      final data = e.response?.data;
      Map<String, dynamic>? validationErrors;
      String message = 'Validation failed';
      if (data is Map) {
        if (data['message'] != null) message = data['message'].toString();
        if (data['errors'] is Map) {
          validationErrors = Map<String, dynamic>.from(data['errors'] as Map);
        }
      }
      return NetworkFailure(
        statusCode: 422,
        message: message,
        validationErrors: validationErrors,
      );
    }

    final serverMessage = e.response?.data is Map && e.response?.data['message'] != null
        ? e.response?.data['message'].toString()
        : e.message ?? 'Server error';

    return NetworkFailure(
      statusCode: statusCode,
      message: serverMessage ?? 'An unexpected network error occurred.',
    );
  }
}

