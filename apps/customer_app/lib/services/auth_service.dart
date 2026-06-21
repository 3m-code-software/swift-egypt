import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:swift_egypt_shared/swift_egypt_shared.dart';
import 'api_service.dart';
import '../core/constants.dart';

class AuthService {
  final ApiService _api;
  final FlutterSecureStorage _storage;

  AuthService(this._api, this._storage);

  Future<AuthResult> login(String email, String password) async {
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    final token = response['token']['access_token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.write(key: AppConstants.storageKeyToken, value: token);
    await _storage.write(key: AppConstants.storageKeyUser, value: jsonEncode(user.toJson()));
    _api.setToken(token);
    return AuthResult(token: token, user: user);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _api.post('/auth/register', body: {
      'full_name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    final token = response['token']['access_token'] as String;
    final user = User.fromJson(response['user'] as Map<String, dynamic>);
    await _storage.write(key: AppConstants.storageKeyToken, value: token);
    await _storage.write(key: AppConstants.storageKeyUser, value: jsonEncode(user.toJson()));
    _api.setToken(token);
    return AuthResult(token: token, user: user);
  }

  Future<AuthResult?> tryAutoLogin() async {
    final token = await _storage.read(key: AppConstants.storageKeyToken);
    if (token == null) return null;
    _api.setToken(token);
    try {
      final response = await _api.get('/users/me');
      final user = User.fromJson(response);
      return AuthResult(token: token, user: user);
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.storageKeyToken);
    await _storage.delete(key: AppConstants.storageKeyUser);
    _api.setToken(null);
  }
}

class AuthResult {
  final String token;
  final User user;
  AuthResult({required this.token, required this.user});
}
