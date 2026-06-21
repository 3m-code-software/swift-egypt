import 'dart:convert';
import 'dart:io';
import '../core/constants.dart';

class ApiService {
  static String? _token;
  static String? _baseUrl;

  static void configure({String? baseUrl}) {
    _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;
  }

  static String get baseUrl => _baseUrl ?? AppConstants.apiBaseUrl;

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path')
          .replace(queryParameters: queryParams);
      final request = await client.getUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      return await _handleResponse(response);
    } catch (e) {
      throw ApiError('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return await _handleResponse(response);
    } catch (e) {
      throw ApiError('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.putUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return await _handleResponse(response);
    } catch (e) {
      throw ApiError('Network error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> uploadFile(
    String path, {
    required String filePath,
    String fieldName = 'file',
  }) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);
      _headers.forEach((k, v) {
        if (k != 'Content-Type') request.headers.set(k, v);
      });
      final boundary = '----${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final body = StringBuffer();
      body.writeln('--$boundary');
      body.writeln(
        'Content-Disposition: form-data; name="$fieldName"; '
        'filename="${file.uri.pathSegments.last}"',
      );
      body.writeln('Content-Type: application/octet-stream');
      body.writeln();
      body.write(String.fromCharCodes(bytes));
      body.writeln();
      body.writeln('--$boundary--');
      request.write(body.toString());
      final response = await request.close();
      return await _handleResponse(response);
    } catch (e) {
      throw ApiError('Upload error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> _handleResponse(
      HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    final data =
        body.isNotEmpty ? jsonDecode(body) : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {'data': data};
    }

    final message =
        (data is Map ? data['message'] : null) as String? ?? 'Unknown error';

    throw ApiError(
      message,
      statusCode: response.statusCode,
    );
  }
}

class ApiError implements Exception {
  final String message;
  final int? statusCode;

  ApiError(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiError($statusCode): $message';
}
