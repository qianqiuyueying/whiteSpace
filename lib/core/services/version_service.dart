import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// 版本信息
class VersionInfo {
  final String version;
  final String buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime publishedAt;

  VersionInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.publishedAt,
  });

  factory VersionInfo.fromGitHubRelease(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? 'v0.0.0';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    
    return VersionInfo(
      version: version,
      buildNumber: json['name'] as String? ?? version,
      releaseNotes: json['body'] as String? ?? '无更新说明',
      downloadUrl: json['html_url'] as String? ?? '',
      publishedAt: DateTime.parse(json['published_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

/// 版本检查服务
/// 
/// 功能：
/// - 获取本地应用版本
/// - 检查 GitHub Releases 最新版本
/// - 比较版本号
class VersionService {
  static const String _repoOwner = 'qianqiuyueying';
  static const String _repoName = 'whiteSpace';
  static const String _githubApiBaseUrl = 'https://api.github.com';

  /// 获取本地应用版本
  static Future<String> getLocalVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// 获取本地应用版本号（数字格式，用于比较）
  static Future<List<int>> getLocalVersionNumbers() async {
    final version = await getLocalVersion();
    return _parseVersion(version);
  }

  /// 从 GitHub 获取最新版本信息
  static Future<VersionInfo?> getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse('$_githubApiBaseUrl/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VersionInfo.fromGitHubRelease(json);
      }
    } catch (e) {
      print('获取最新版本失败：$e');
    }
    return null;
  }

  /// 检查是否有新版本
  /// 返回：如果有新版本返回 VersionInfo，否则返回 null
  static Future<VersionInfo?> checkForUpdates() async {
    try {
      final localVersion = await getLocalVersionNumbers();
      final latestVersion = await getLatestVersion();

      if (latestVersion == null) {
        return null;
      }

      final remoteVersion = _parseVersion(latestVersion.version);

      // 比较版本号
      if (_isNewer(remoteVersion, localVersion)) {
        return latestVersion;
      }
    } catch (e) {
      print('检查更新失败：$e');
    }
    return null;
  }

  /// 解析版本号字符串为数字列表
  /// 例如："1.2.3" -> [1, 2, 3]
  static List<int> _parseVersion(String version) {
    // 移除可能的 'v' 前缀
    final cleanVersion = version.startsWith('v') ? version.substring(1) : version;
    final parts = cleanVersion.split('.');
    final numbers = <int>[];
    
    for (final part in parts) {
      // 只取数字部分
      final digits = part.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        numbers.add(int.tryParse(digits) ?? 0);
      } else {
        numbers.add(0);
      }
    }
    
    // 确保至少有 3 位
    while (numbers.length < 3) {
      numbers.add(0);
    }
    
    return numbers;
  }

  /// 判断 remote 是否比 local 新
  /// 使用语义化版本比较规则
  static bool _isNewer(List<int> remote, List<int> local) {
    for (int i = 0; i < 3; i++) {
      if (remote[i] > local[i]) {
        return true;
      } else if (remote[i] < local[i]) {
        return false;
      }
    }
    return false; // 版本相同
  }

  /// 获取所有 Releases 列表（可选功能，用于显示更新历史）
  static Future<List<VersionInfo>> getAllReleases() async {
    final releases = <VersionInfo>[];
    
    try {
      final response = await http.get(
        Uri.parse('$_githubApiBaseUrl/repos/$_repoOwner/$_repoName/releases'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        for (final json in jsonList) {
          releases.add(VersionInfo.fromGitHubRelease(json as Map<String, dynamic>));
        }
      }
    } catch (e) {
      print('获取 Releases 列表失败：$e');
    }
    
    return releases;
  }
}
