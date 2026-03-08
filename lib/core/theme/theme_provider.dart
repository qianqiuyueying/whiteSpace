import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式
enum AppThemeMode {
  system('跟随系统'),
  light('浅色模式'),
  dark('深色模式');

  final String label;
  const AppThemeMode(this.label);
}

/// 主题状态
class ThemeState {
  final AppThemeMode mode;
  final bool isDark;

  const ThemeState({
    required this.mode,
    required this.isDark,
  });

  ThemeState copyWith({
    AppThemeMode? mode,
    bool? isDark,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
    );
  }
}

/// 主题状态管理器
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeModeKey = 'theme_mode';

  ThemeNotifier() : super(const ThemeState(mode: AppThemeMode.system, isDark: false)) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final mode = AppThemeMode.values[modeIndex];
    
    // 获取系统主题
    final isDark = _getIsDarkForMode(mode);
    
    state = ThemeState(mode: mode, isDark: isDark);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    
    final isDark = _getIsDarkForMode(mode);
    state = ThemeState(mode: mode, isDark: isDark);
  }

  void updateSystemTheme(bool isSystemDark) {
    if (state.mode == AppThemeMode.system) {
      state = state.copyWith(isDark: isSystemDark);
    }
  }

  bool _getIsDarkForMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        // 默认返回 false，实际值由 WidgetsBindingObserver 更新
        return false;
    }
  }
}

/// 主题状态 Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});