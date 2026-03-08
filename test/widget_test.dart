// 留白日记应用单元测试
//
// 测试核心模型和服务

import 'package:flutter_test/flutter_test.dart';
import 'package:white_space_qwen/features/diary/data/models/diary_entry.dart';
import 'package:white_space_qwen/shared/widgets/diary_card.dart';

void main() {
  group('DiaryEntry Model Tests', () {
    test('DiaryEntry should be created with default values', () {
      final entry = DiaryEntry()
        ..content = 'Test content';

      expect(entry.content, 'Test content');
      expect(entry.moodIndex, 7); // 默认 neutral
      expect(entry.tags, isEmpty);
      expect(entry.images, isEmpty);
      expect(entry.isDeleted, false);
      expect(entry.isSynced, false);
    });

    test('DiaryEntry should serialize to JSON correctly', () {
      final entry = DiaryEntry()
        ..title = 'Test Title'
        ..content = 'Test content'
        ..moodIndex = 0
        ..tags = ['tag1', 'tag2'];

      final json = entry.toJson();

      expect(json['title'], 'Test Title');
      expect(json['content'], 'Test content');
      expect(json['moodIndex'], 0);
      expect(json['tags'], ['tag1', 'tag2']);
    });

    test('DiaryEntry should deserialize from JSON correctly', () {
      final json = {
        'uuid': 'test-uuid',
        'title': 'Test Title',
        'content': 'Test content',
        'moodIndex': 3,
        'tags': ['tag1'],
        'images': [],
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final entry = DiaryEntry.fromJson(json);

      expect(entry.title, 'Test Title');
      expect(entry.content, 'Test content');
      expect(entry.moodIndex, 3);
      expect(entry.tags, ['tag1']);
    });
  });

  group('Mood Enum Tests', () {
    test('Mood enum should have correct values', () {
      expect(Mood.values.length, 8);
      expect(Mood.happy.label, '开心');
      expect(Mood.happy.emoji, '😊');
      expect(Mood.neutral.label, '一般');
      expect(Mood.neutral.emoji, '😐');
    });
  });

  group('Weather Enum Tests', () {
    test('Weather enum should have correct values', () {
      expect(Weather.values.length, 6);
      expect(Weather.sunny.label, '晴');
      expect(Weather.sunny.emoji, '☀️');
      expect(Weather.rainy.label, '雨');
      expect(Weather.rainy.emoji, '🌧️');
    });
  });
}