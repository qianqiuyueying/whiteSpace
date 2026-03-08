import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/gist_service.dart';
import '../data/models/user_profile.dart';

/// 认证状态
class AuthState {
  final bool isLoading;
  final bool isBound; // 是否已绑定 GitHub Token
  final UserProfile? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isBound = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isBound,
    UserProfile? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isBound: isBound ?? this.isBound,
      user: user ?? this.user,
      error: error,
    );
  }
}

/// 认证状态管理器
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final GistService _gistService;
  final DatabaseService _databaseService;

  AuthNotifier(this._authService, this._gistService, this._databaseService)
      : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// 检查认证状态
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        _gistService.setToken(token);

        // 验证 token 是否有效
        final isValid = await _gistService.isTokenValid();
        if (isValid) {
          final user = await _databaseService.getCurrentUser();
          state = state.copyWith(
            isLoading: false,
            isBound: true,
            user: user,
          );
        } else {
          // Token 无效，清除
          await _authService.deleteToken();
          state = state.copyWith(isLoading: false);
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 绑定 GitHub Token
  Future<bool> bindToken(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      _gistService.setToken(token);

      // 验证 token
      final userData = await _gistService.getCurrentUser();
      if (userData == null) {
        _gistService.clearToken();
        state = state.copyWith(isLoading: false, error: 'Token 无效');
        return false;
      }

      // 保存 token
      await _authService.saveToken(token);

      // 创建/更新用户信息
      final user = UserProfile()
        ..username = userData['login'] ?? ''
        ..avatarUrl = userData['avatar_url']
        ..githubId = userData['id']?.toString()
        ..createdAt = DateTime.now();

      await _databaseService.saveUser(user);

      state = state.copyWith(
        isLoading: false,
        isBound: true,
        user: user,
      );

      return true;
    } catch (e) {
      _gistService.clearToken();
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// 解绑 GitHub Token
  Future<void> unbindToken() async {
    state = state.copyWith(isLoading: true);

    try {
      _gistService.clearToken();
      await _authService.clearAll();
      await _databaseService.deleteUser();

      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 更新用户信息
  Future<void> updateUser(UserProfile user) async {
    await _databaseService.saveUser(user);
    state = state.copyWith(user: user);
  }
}

/// 认证状态 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final gistService = ref.watch(gistServiceProvider);
  final databaseService = ref.watch(databaseServiceProvider).valueOrNull;

  if (databaseService == null) {
    throw StateError('Database not initialized');
  }

  return AuthNotifier(authService, gistService, databaseService);
});