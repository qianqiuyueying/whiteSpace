/// 应用常量配置
class AppConstants {
  AppConstants._();

  static const String appName = '留白日记';
  static const String appVersion = '1.0.0';

  // GitHub API 配置
  static const String githubApiBaseUrl = 'https://api.github.com';
  static const String gistApiUrl = '$githubApiBaseUrl/gists';
  
  // 存储 Key
  static const String tokenKey = 'github_token';
  static const String userInfoKey = 'user_info';
  static const String themeKey = 'theme_mode';
  static const String gistIdKey = 'gist_id';
  
  // 数据格式
  static const String diaryFilePrefix = 'diary_';
  static const String configFile = 'config.json';
  static const String tagsFile = 'tags.json';
}

/// 心情类型
enum Mood {
  happy('开心', '😊'),
  calm('平静', '😌'),
  sad('难过', '😢'),
  angry('生气', '😠'),
  anxious('焦虑', '😰'),
  excited('兴奋', '🤩'),
  tired('疲惫', '😴'),
  neutral('一般', '😐');

  final String label;
  final String emoji;

  const Mood(this.label, this.emoji);
}

/// 天气类型
enum Weather {
  sunny('晴', '☀️'),
  cloudy('多云', '⛅'),
  rainy('雨', '🌧️'),
  snowy('雪', '❄️'),
  windy('风', '💨'),
  foggy('雾', '🌫️');

  final String label;
  final String emoji;

  const Weather(this.label, this.emoji);
}