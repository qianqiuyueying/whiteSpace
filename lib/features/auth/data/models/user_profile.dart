import 'package:isar/isar.dart';

part 'user_profile.g.dart';

/// 用户配置模型
@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  /// GitHub 用户名
  late String username;

  /// GitHub 用户头像 URL
  String? avatarUrl;

  /// GitHub 用户 ID
  String? githubId;

  /// Gist ID (存储日记的 Gist)
  String? gistId;

  /// 同步时间
  DateTime? lastSyncAt;

  /// 创建时间
  late DateTime createdAt;

  UserProfile();

  /// 从 JSON 创建
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserProfile();
    profile.username = json['username'] ?? '';
    profile.avatarUrl = json['avatarUrl'];
    profile.githubId = json['githubId'];
    profile.gistId = json['gistId'];
    profile.lastSyncAt = json['lastSyncAt'] != null 
        ? DateTime.parse(json['lastSyncAt']) 
        : null;
    profile.createdAt = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    return profile;
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'avatarUrl': avatarUrl,
      'githubId': githubId,
      'gistId': gistId,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}