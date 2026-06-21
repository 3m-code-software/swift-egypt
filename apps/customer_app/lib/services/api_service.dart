import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/constants.dart';

class ApiService {
  static final ApiClient _client = ApiClient(baseUrl: AppConstants.apiBaseUrl);

  void setToken(String? token) => _client.setToken(token);

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    return _client.get(path, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    return _client.post(path, body: body);
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    return _client.put(path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _client.delete(path);
  }

  Future<Map<String, dynamic>> uploadFile(String path,
      {required String filePath, String fieldName = 'file'}) async {
    return _client.uploadFile(path, filePath: filePath, fieldName: fieldName);
  }
}
