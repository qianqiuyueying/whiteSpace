import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// 认证服务
class AuthService {
  final FlutterSecureStorage _storage;

  AuthService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 保存 GitHub Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  /// 获取 GitHub Token
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  /// 删除 Token
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  /// 保存 Gist ID
  Future<void> saveGistId(String gistId) async {
    await _storage.write(key: AppConstants.gistIdKey, value: gistId);
  }

  /// 获取 Gist ID
  Future<String?> getGistId() async {
    return await _storage.read(key: AppConstants.gistIdKey);
  }

  /// 删除 Gist ID
  Future<void> deleteGistId() async {
    await _storage.delete(key: AppConstants.gistIdKey);
  }

  /// 清除所有认证信息
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// 认证服务 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});