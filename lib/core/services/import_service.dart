import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/diary/data/models/diary_entry.dart';
import 'database_service.dart';

/// 导入结果
class ImportResult {
  final bool success;
  final int count;
  final List<String> errors;

  const ImportResult({
    required this.success,
    this.count = 0,
    this.errors = const [],
  });
}

/// 数据导入服务
class ImportService {
  final DatabaseService _databaseService;

  ImportService(this._databaseService);

  /// 从 JSON 文件导入
  Future<ImportResult> importFromJson(String content) async {
    try {
      final List<dynamic> jsonList = jsonDecode(content);
      final entries = <DiaryEntry>[];
      final errors = <String>[];

      for (int i = 0; i < jsonList.length; i++) {
        try {
          final entry = DiaryEntry.fromJson(jsonList[i]);
          entries.add(entry);
        } catch (e) {
          errors.add('第 ${i + 1} 条记录解析失败: $e');
        }
      }

      await _databaseService.saveDiaries(entries);
      return ImportResult(success: true, count: entries.length, errors: errors);
    } catch (e) {
      return ImportResult(success: false, errors: ['JSON 解析失败: $e']);
    }
  }

  /// 从 Day One JSON 导入
  Future<ImportResult> importFromDayOne(String content) async {
    try {
      final data = jsonDecode(content);
      final entries = data['entries'] as List<dynamic>;
      final importedEntries = <DiaryEntry>[];
      final errors = <String>[];

      for (final entry in entries) {
        try {
          final diary = DiaryEntry()
            ..uuid = const Uuid().v4()
            ..title = entry['title'] ?? ''
            ..content = _convertDayOneContent(entry)
            ..createdAt = DateTime.parse(entry['creationDate'])
            ..updatedAt = DateTime.parse(entry['modifiedDate'] ?? entry['creationDate'])
            ..moodIndex = _mapDayOneRating(entry['rating'])
            ..tags = List<String>.from(entry['tags'] ?? [])
            ..location = entry['location']?['localityName'];

          importedEntries.add(diary);
        } catch (e) {
          errors.add('导入失败: $e');
        }
      }

      await _databaseService.saveDiaries(importedEntries);
      return ImportResult(success: true, count: importedEntries.length, errors: errors);
    } catch (e) {
      return ImportResult(success: false, errors: ['Day One 格式解析失败: $e']);
    }
  }

  String _convertDayOneContent(Map<String, dynamic> entry) {
    final text = entry['text'] ?? '';
    // Day One 使用 Markdown，直接返回
    return text;
  }

  int _mapDayOneRating(dynamic rating) {
    if (rating == null) return 7; // neutral
    final r = rating as int;
    if (r >= 4) return 0; // happy
    if (r == 3) return 1; // calm
    if (r == 2) return 2; // sad
    return 3; // angry
  }

  /// 从 Journey JSON 导入
  Future<ImportResult> importFromJourney(String content) async {
    try {
      final data = jsonDecode(content);
      final entries = data['entries'] as List<dynamic>;
      final importedEntries = <DiaryEntry>[];
      final errors = <String>[];

      for (final entry in entries) {
        try {
          final diary = DiaryEntry()
            ..uuid = const Uuid().v4()
            ..title = entry['title'] ?? ''
            ..content = entry['text'] ?? ''
            ..createdAt = DateTime.fromMillisecondsSinceEpoch(entry['date'] * 1000)
            ..updatedAt = DateTime.fromMillisecondsSinceEpoch(entry['date_modified'] * 1000 ?? entry['date'] * 1000)
            ..moodIndex = _mapJourneyMood(entry['mood'])
            ..tags = List<String>.from(entry['tags'] ?? []);

          importedEntries.add(diary);
        } catch (e) {
          errors.add('导入失败: $e');
        }
      }

      await _databaseService.saveDiaries(importedEntries);
      return ImportResult(success: true, count: importedEntries.length, errors: errors);
    } catch (e) {
      return ImportResult(success: false, errors: ['Journey 格式解析失败: $e']);
    }
  }

  int _mapJourneyMood(String? mood) {
    if (mood == null) return 7;
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'excited':
        return 0;
      case 'calm':
      case 'peaceful':
        return 1;
      case 'sad':
      case 'depressed':
        return 2;
      case 'angry':
      case 'frustrated':
        return 3;
      case 'anxious':
        return 4;
      case 'tired':
        return 6;
      default:
        return 7;
    }
  }

  /// 从纯文本导入（每篇日记用空行分隔）
  Future<ImportResult> importFromPlainText(String content) async {
    try {
      final blocks = content.split(RegExp(r'\n\s*\n\s*\n'));
      final importedEntries = <DiaryEntry>[];
      final errors = <String>[];

      for (final block in blocks) {
        if (block.trim().isEmpty) continue;

        try {
          final lines = block.trim().split('\n');
          final title = lines.first.trim();
          final body = lines.skip(1).join('\n').trim();

          final diary = DiaryEntry()
            ..uuid = const Uuid().v4()
            ..title = title.isNotEmpty ? title : null
            ..content = body.isNotEmpty ? body : block.trim()
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          importedEntries.add(diary);
        } catch (e) {
          errors.add('导入失败: $e');
        }
      }

      await _databaseService.saveDiaries(importedEntries);
      return ImportResult(success: true, count: importedEntries.length, errors: errors);
    } catch (e) {
      return ImportResult(success: false, errors: ['文本解析失败: $e']);
    }
  }

  /// 从 Markdown 文件导入
  Future<ImportResult> importFromMarkdown(String content) async {
    try {
      // 使用 --- 分隔不同的日记
      final blocks = content.split(RegExp(r'\n---+\n'));
      final importedEntries = <DiaryEntry>[];
      final errors = <String>[];

      for (final block in blocks) {
        if (block.trim().isEmpty) continue;

        try {
          final lines = block.trim().split('\n');
          String? title;
          final contentLines = <String>[];

          for (final line in lines) {
            if (line.startsWith('# ') && title == null) {
              title = line.substring(2).trim();
            } else {
              contentLines.add(line);
            }
          }

          final diary = DiaryEntry()
            ..uuid = const Uuid().v4()
            ..title = title
            ..content = contentLines.join('\n').trim()
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          importedEntries.add(diary);
        } catch (e) {
          errors.add('导入失败: $e');
        }
      }

      await _databaseService.saveDiaries(importedEntries);
      return ImportResult(success: true, count: importedEntries.length, errors: errors);
    } catch (e) {
      return ImportResult(success: false, errors: ['Markdown 解析失败: $e']);
    }
  }

  /// 自动检测格式并导入
  Future<ImportResult> autoImport(String content, String fileName) async {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'json':
        // 尝试检测具体格式
        try {
          final data = jsonDecode(content);
          if (data is List) {
            return importFromJson(content);
          } else if (data is Map && data.containsKey('entries')) {
            // 可能是 Day One 或 Journey
            if (data['entries'].first?.containsKey('creationDate') ?? false) {
              return importFromDayOne(content);
            }
            return importFromJourney(content);
          }
        } catch (e) {
          return ImportResult(success: false, errors: ['无法识别的 JSON 格式']);
        }
        break;
      case 'md':
      case 'markdown':
        return importFromMarkdown(content);
      case 'txt':
        return importFromPlainText(content);
    }

    return const ImportResult(success: false, errors: ['不支持的文件格式']);
  }
}

/// 导入服务 Provider
final importServiceProvider = Provider<ImportService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider).valueOrNull;
  if (databaseService == null) {
    throw StateError('Database not initialized');
  }
  return ImportService(databaseService);
});