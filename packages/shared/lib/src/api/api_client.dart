import 'dart:convert';
import 'dart:io';
import 'api_exception.dart';

class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  String? _token;

  ApiClient({
    required this.baseUrl,
    Map<String, String>? headers,
  }) : defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        };

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(defaultHeaders);
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path')
          .replace(queryParameters: queryParams);
      final request = await client.getUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> post(String path,
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
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> put(String path,
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
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.deleteUrl(uri);
      _headers.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> uploadFile(String path,
      {required String filePath, String fieldName = 'file'}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);
      _headers.forEach((k, v) {
        if (k != 'Content-Type') request.headers.set(k, v);
      });
      request.headers.set('Content-Type', 'multipart/form-data');
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final boundary = '----${DateTime.now().millisecondsSinceEpoch}';
      request.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');
      final body = StringBuffer();
      body.writeln('--$boundary');
      body.writeln('Content-Disposition: form-data; name="$fieldName"; filename="${file.uri.pathSegments.last}"');
      body.writeln('Content-Type: application/octet-stream');
      body.writeln();
      body.write(String.fromCharCodes(bytes));
      body.writeln();
      body.writeln('--$boundary--');
      request.write(body.toString());
      final response = await request.close();
      return _handleResponse(response);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> _handleResponse(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    final data = body.isNotEmpty ? jsonDecode(body) : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {'data': data};
    }

    final message = data['message'] as String? ?? 'Unknown error';
    final errors = data['errors'] as Map<String, dynamic>?;

    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        throw ValidationException(message, errors);
      default:
        throw ApiException(
          statusCode: response.statusCode,
          message: message,
          errors: errors,
        );
    }
  }
}
