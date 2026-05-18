import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://dummyjson.com/',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('--> ${options.method} ${options.baseUrl}${options.path}');
            print('Headers: ${options.headers}');
            if (options.data != null) {
              print('Body: ${options.data}');
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('<-- ${response.statusCode} ${response.requestOptions.path}');
            print('Response: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print('<-- ERROR ${e.response?.statusCode} ${e.requestOptions.path}');
            print('Message: ${e.message}');
            if (e.response?.data != null) {
              print('Error response: ${e.response?.data}');
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // GET Request
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // POST Request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // PUT Request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // DELETE Request
  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw 'An unexpected error occurred: $e';
    }
  }

  // Robust Error Handling
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout with the server. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout in association with server. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout in connection with server.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        if (responseData != null && responseData is Map && responseData.containsKey('message')) {
          return responseData['message'].toString();
        }
        return 'Received invalid response from server (Status: $statusCode).';
      case DioExceptionType.cancel:
        return 'Request to the server was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection detected. Please verify your network.';
      case DioExceptionType.unknown:
      default:
        return 'Unexpected network issue occurred. Please try again later.';
    }
  }
}
