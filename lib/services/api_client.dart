import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// Categorized error thrown by the API client. UI layers only ever see this
/// type, so no stack traces or sensitive details leak to the user.
enum ApiErrorKind {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  server,
  noConnection,
  timeout,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  const ApiException(this.kind, this.message, {this.statusCode});

  /// User-friendly message per error kind.
  String get userMessage => switch (kind) {
        ApiErrorKind.badRequest => _message,
        ApiErrorKind.unauthorized =>
          'Your session has expired. Please log in again.',
        ApiErrorKind.forbidden => 'You do not have permission to do this.',
        ApiErrorKind.notFound => 'Requested data was not found.',
        ApiErrorKind.rateLimited =>
          'Too many requests. Please wait a moment and try again.',
        ApiErrorKind.server =>
          'Something went wrong on our side. Please try again later.',
        ApiErrorKind.noConnection =>
          'No internet connection. Please check your network.',
        ApiErrorKind.timeout =>
          'The request timed out. Please check your connection and try again.',
        ApiErrorKind.unknown => 'Unexpected error. Please try again.',
      };

  String get _message => message;

  @override
  String toString() => 'ApiException(${kind.name}): $message';
}

/// Low-level HTTP client with centralized error handling.
///
/// All requests time out, attach `Content-Type`/`Accept` headers and, when a
/// token is provided, `Authorization: Bearer <token>`.
class ApiClient {
  ApiClient._();

  static final http.Client _client = http.Client();

  static Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  static Future<http.Response> _guard(Future<http.Response> request) async {
    try {
      return await request.timeout(AppConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.timeout, 'Request timed out.');
    } on SocketException {
      throw const ApiException(ApiErrorKind.noConnection, 'No internet connection.');
    } on http.ClientException catch (e) {
      throw ApiException(ApiErrorKind.noConnection,
          'Network unavailable (${e.message}).');
    }
  }

  static Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final response = await _guard(_client.get(uri, headers: _headers(token)));
    return _decode(response);
  }

  static Future<dynamic> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final response = await _guard(_client.post(
      uri,
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    ));
    return _decode(response);
  }

  static Future<dynamic> put(
    String path, {
    required String token,
    Map<String, dynamic>? body,
  }) async {
    final response = await _guard(_client.put(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers(token),
      body: body == null ? null : jsonEncode(body),
    ));
    return _decode(response);
  }

  static Future<dynamic> delete(String path, {required String token}) async {
    final response = await _guard(_client.delete(
      Uri.parse('${AppConstants.apiBaseUrl}$path'),
      headers: _headers(token),
    ));
    return _decode(response);
  }

  static dynamic _decode(http.Response response) {
    if (_isSuccess(response.statusCode)) {
      if (response.body.isEmpty) return null;
      final decoded = utf8.decode(response.bodyBytes);
      try {
        return jsonDecode(decoded);
      } catch (_) {
        return {'message': decoded};
      }
    }
    throw _toException(response);
  }

  static bool _isSuccess(int code) => code >= 200 && code < 300;

  static ApiException _toException(http.Response response) {
    final kind = switch (response.statusCode) {
      400 => ApiErrorKind.badRequest,
      401 => ApiErrorKind.unauthorized,
      403 => ApiErrorKind.forbidden,
      404 => ApiErrorKind.notFound,
      429 => ApiErrorKind.rateLimited,
      >= 500 => ApiErrorKind.server,
      _ => ApiErrorKind.unknown,
    };

    var serverMessage = '';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['error'] != null) {
        serverMessage = decoded['error'].toString();
      }
    } catch (_) {
      // Non-JSON body; fall back to generic message.
    }

    final fallback = switch (kind) {
      ApiErrorKind.badRequest => 'Invalid input. Please check your details.',
      ApiErrorKind.unauthorized => 'Invalid email or password.',
      ApiErrorKind.forbidden => 'Forbidden. You cannot access this resource.',
      ApiErrorKind.notFound => 'The requested resource was not found.',
      ApiErrorKind.rateLimited => 'Too many requests. Please slow down.',
      ApiErrorKind.server => 'The server encountered an error.',
      ApiErrorKind.unknown => 'Something went wrong (${response.statusCode}).',
      _ => 'Something went wrong.',
    };

    return ApiException(kind, serverMessage.isNotEmpty ? serverMessage : fallback,
        statusCode: response.statusCode);
  }
}