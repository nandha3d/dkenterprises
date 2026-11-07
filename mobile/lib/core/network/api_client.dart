import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../storage/secure_storage_service.dart';
import 'api_result.dart';

/// Industrial HTTP Client wrapper for Zolo ERP Mobile.
class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;
  final Uuid _uuid = const Uuid();

  ApiClient(this._storage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _storage.getServerUrl(),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
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
          if (options.method == 'POST' || options.method == 'PUT') {
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

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return ApiSuccess(fromJson(response.data));
      }
      return ApiFailure(
        NetworkFailure(
          statusCode: response.statusCode,
          message: 'Server error: ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return ApiFailure(_mapDioError(e));
    } catch (e) {
      return ApiFailure(
        NetworkFailure(message: 'Unexpected client error: $e'),
      );
    }
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final options = Options();
      if (idempotencyKey != null) {
        options.headers = {'Idempotency-Key': idempotencyKey};
      }
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return ApiSuccess(fromJson(response.data));
      }
      return ApiFailure(
        NetworkFailure(
          statusCode: response.statusCode,
          message: 'Server error: ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return ApiFailure(_mapDioError(e));
    } catch (e) {
      return ApiFailure(
        NetworkFailure(message: 'Unexpected client error: $e'),
      );
    }
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return ApiSuccess(fromJson(response.data));
      }
      return ApiFailure(
        NetworkFailure(
          statusCode: response.statusCode,
          message: 'Server error: ${response.statusCode}',
        ),
      );
    } on DioException catch (e) {
      return ApiFailure(_mapDioError(e));
    } catch (e) {
      return ApiFailure(
        NetworkFailure(message: 'Unexpected client error: $e'),
      );
    }
  }

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

