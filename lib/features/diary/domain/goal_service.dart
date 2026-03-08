import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/database_service.dart';
import '../data/models/diary_entry.dart';

/// 写作目标类型
enum GoalType {
  daily('每日', '每天写日记'),
  weekly('每周', '每周写日记'),
  monthly('每月', '每月写日记');

  final String label;
  final String description;

  const GoalType(this.label, this.description);
}

/// 写作目标单位
enum GoalUnit {
  entries('篇数', '篇'),
  words('字数', '字');

  final String label;
  final String unit;

  const GoalUnit(this.label, this.unit);
}

/// 写作目标
class WritingGoal {
  final GoalType type;
  final GoalUnit unit;
  final int target;
  final bool enabled;

  const WritingGoal({
    required this.type,
    required this.unit,
    required this.target,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'unit': unit.index,
      'target': target,
      'enabled': enabled,
    };
  }

  factory WritingGoal.fromJson(Map<String, dynamic> json) {
    return WritingGoal(
      type: GoalType.values[json['type'] ?? 0],
      unit: GoalUnit.values[json['unit'] ?? 0],
      target: json['target'] ?? 1,
      enabled: json['enabled'] ?? true,
    );
  }

  WritingGoal copyWith({
    GoalType? type,
    GoalUnit? unit,
    int? target,
    bool? enabled,
  }) {
    return WritingGoal(
      type: type ?? this.type,
      unit: unit ?? this.unit,
      target: target ?? this.target,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// 目标进度
class GoalProgress {
  final WritingGoal goal;
  final int current;
  final int target;
  final double percentage;
  final bool achieved;
  final DateTime periodStart;
  final DateTime periodEnd;

  const GoalProgress({
    required this.goal,
    required this.current,
    required this.target,
    required this.percentage,
    required this.achieved,
    required this.periodStart,
    required this.periodEnd,
  });

  String get progressText => '$current / $target ${goal.unit.unit}';
}

/// 写作目标服务
class GoalService {
  static const String _goalsKey = 'writing_goals';

  Future<List<WritingGoal>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_goalsKey);

    if (jsonStr == null) {
      // 默认目标
      return [
        const WritingGoal(type: GoalType.daily, unit: GoalUnit.entries, target: 1),
      ];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => WritingGoal.fromJson(e)).toList();
    } catch (e) {
      return [
        const WritingGoal(type: GoalType.daily, unit: GoalUnit.entries, target: 1),
      ];
    }
  }

  Future<void> saveGoals(List<WritingGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = goals.map((e) => e.toJson()).toList();
    await prefs.setString(_goalsKey, jsonEncode(jsonList));
  }

  /// 计算目标进度
  Future<GoalProgress> calculateProgress(WritingGoal goal) async {
    final db = await DatabaseService.getInstance();
    final now = DateTime.now();

    DateTime periodStart;
    DateTime periodEnd;

    switch (goal.type) {
      case GoalType.daily:
        periodStart = DateTime(now.year, now.month, now.day);
        periodEnd = periodStart.add(const Duration(days: 1));
        break;
      case GoalType.weekly:
        final weekday = now.weekday;
        periodStart = DateTime(now.year, now.month, now.day - weekday + 1);
        periodEnd = periodStart.add(const Duration(days: 7));
        break;
      case GoalType.monthly:
        periodStart = DateTime(now.year, now.month, 1);
        periodEnd = DateTime(now.year, now.month + 1, 1);
        break;
    }

    final diaries = await db.getAllDiaries();
    final periodDiaries = diaries.where((d) =>
      d.createdAt.isAfter(periodStart) && d.createdAt.isBefore(periodEnd)
    ).toList();

    int current;
    if (goal.unit == GoalUnit.entries) {
      current = periodDiaries.length;
    } else {
      current = periodDiaries.fold(0, (sum, d) => sum + d.content.length);
    }

    final percentage = (current / goal.target).clamp(0.0, 1.0);
    final achieved = current >= goal.target;

    return GoalProgress(
      goal: goal,
      current: current,
      target: goal.target,
      percentage: percentage,
      achieved: achieved,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  /// 计算所有目标进度
  Future<List<GoalProgress>> calculateAllProgress() async {
    final goals = await loadGoals();
    final enabledGoals = goals.where((g) => g.enabled).toList();

    final progressList = <GoalProgress>[];
    for (final goal in enabledGoals) {
      final progress = await calculateProgress(goal);
      progressList.add(progress);
    }

    return progressList;
  }
}

/// 目标服务 Provider
final goalServiceProvider = Provider<GoalService>((ref) {
  return GoalService();
});

/// 目标列表 Provider
final goalsProvider = FutureProvider<List<WritingGoal>>((ref) async {
  final service = ref.read(goalServiceProvider);
  return service.loadGoals();
});

/// 目标进度 Provider
final goalProgressProvider = FutureProvider<List<GoalProgress>>((ref) async {
  final service = ref.read(goalServiceProvider);
  return service.calculateAllProgress();
});