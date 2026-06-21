import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import '../core/constants.dart';
import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  static Future<void> saveUser(User user) async {
    await _storage.write(
      key: AppConstants.userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  static Future<User?> getUser() async {
    final data = await _storage.read(key: AppConstants.userKey);
    if (data == null) return null;
    return User.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: AppConstants.userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = response['token']['access_token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await saveToken(token);
    await saveUser(user);
    ApiService.setToken(token);
    return {'token': token, 'user': user};
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout');
    } catch (_) {}
    await deleteToken();
    await deleteUser();
    ApiService.setToken(null);
  }

  static Future<User?> autoLogin() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    ApiService.setToken(token);
    try {
      final response = await ApiService.get('/users/me');
      final user = User.fromJson(response);
      await saveUser(user);
      return user;
    } catch (_) {
      await deleteToken();
      await deleteUser();
      return null;
    }
  }
}
