import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 草稿数据
class DraftData {
  final String? title;
  final String content;
  final int moodIndex;
  final int? weatherIndex;
  final List<String> tags;
  final List<String> images;
  final DateTime lastSavedAt;

  DraftData({
    this.title,
    required this.content,
    this.moodIndex = 7,
    this.weatherIndex,
    this.tags = const [],
    this.images = const [],
    required this.lastSavedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'moodIndex': moodIndex,
      'weatherIndex': weatherIndex,
      'tags': tags,
      'images': images,
      'lastSavedAt': lastSavedAt.toIso8601String(),
    };
  }

  factory DraftData.fromJson(Map<String, dynamic> json) {
    return DraftData(
      title: json['title'],
      content: json['content'] ?? '',
      moodIndex: json['moodIndex'] ?? 7,
      weatherIndex: json['weatherIndex'],
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      lastSavedAt: DateTime.parse(json['lastSavedAt']),
    );
  }
}

/// 草稿服务
class DraftService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _draftKey = 'current_draft';

  /// 保存草稿
  Future<void> saveDraft(DraftData draft) async {
    final json = jsonEncode(draft.toJson());
    await _storage.write(key: _draftKey, value: json);
  }

  /// 获取草稿
  Future<DraftData?> getDraft() async {
    final json = await _storage.read(key: _draftKey);
    if (json == null) return null;

    try {
      return DraftData.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// 清除草稿
  Future<void> clearDraft() async {
    await _storage.delete(key: _draftKey);
  }

  /// 检查是否有草稿
  Future<bool> hasDraft() async {
    final draft = await getDraft();
    return draft != null && draft.content.isNotEmpty;
  }
}

final draftServiceProvider = Provider<DraftService>((ref) {
  return DraftService();
});