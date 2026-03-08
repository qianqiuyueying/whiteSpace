import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GitHub Gist API 服务
class GistService {
  final Dio _dio;
  String? _token;

  GistService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://api.github.com',
    headers: {
      'Accept': 'application/vnd.github.v3+json',
    },
  ));

  /// 设置认证 Token
  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'token $token';
  }

  /// 清除认证 Token
  void clearToken() {
    _token = null;
    _dio.options.headers.remove('Authorization');
  }

  /// 获取当前用户信息
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _dio.get('/user');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    }
  }

  /// 获取用户的 Gists 列表
  Future<List<Map<String, dynamic>>> getGists({int page = 1, int perPage = 100}) async {
    try {
      final response = await _dio.get('/gists', queryParameters: {
        'page': page,
        'per_page': perPage,
      });
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取单个 Gist
  Future<Map<String, dynamic>?> getGist(String gistId) async {
    try {
      final response = await _dio.get('/gists/$gistId');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// 创建 Gist
  Future<Map<String, dynamic>> createGist({
    required String description,
    required Map<String, String> files,
    bool isPublic = false,
  }) async {
    try {
      final response = await _dio.post('/gists', data: {
        'description': description,
        'public': isPublic,
        'files': files.map((key, value) => MapEntry(key, {'content': value})),
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// 更新 Gist
  Future<Map<String, dynamic>> updateGist({
    required String gistId,
    String? description,
    Map<String, String>? files,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (description != null) {
        data['description'] = description;
      }
      if (files != null) {
        data['files'] = files.map((key, value) => MapEntry(key, {'content': value}));
      }
      final response = await _dio.patch('/gists/$gistId', data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// 删除 Gist 文件 (通过更新 Gist 实现)
  Future<Map<String, dynamic>> deleteGistFile({
    required String gistId,
    required String fileName,
  }) async {
    try {
      final response = await _dio.patch('/gists/$gistId', data: {
        'files': {
          fileName: null, // 设置为 null 删除文件
        },
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// 删除整个 Gist
  Future<void> deleteGist(String gistId) async {
    try {
      await _dio.delete('/gists/$gistId');
    } catch (e) {
      rethrow;
    }
  }

  /// 检查 Token 是否有效
  Future<bool> isTokenValid() async {
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }
}

/// Gist 服务 Provider
final gistServiceProvider = Provider<GistService>((ref) {
  return GistService();
});