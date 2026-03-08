import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/gist_service.dart';
import '../../../core/services/auth_service.dart';
import '../../sync/presentation/sync_provider.dart';
import '../data/models/diary_entry.dart';

/// 日记列表状态
class DiaryListState {
  final List<DiaryEntry> diaries;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedTag;

  const DiaryListState({
    this.diaries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedTag,
  });

  DiaryListState copyWith({
    List<DiaryEntry>? diaries,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedTag,
  }) {
    return DiaryListState(
      diaries: diaries ?? this.diaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: selectedTag,
    );
  }
}

/// 日记列表状态管理器
class DiaryListNotifier extends StateNotifier<DiaryListState> {
  final DatabaseService _databaseService;

  DiaryListNotifier(this._databaseService) : super(const DiaryListState()) {
    loadDiaries();
  }

  /// 加载日记列表
  Future<void> loadDiaries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final diaries = await _databaseService.getAllDiaries();
      state = state.copyWith(isLoading: false, diaries: diaries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 搜索日记
  Future<void> searchDiaries(String query) async {
    state = state.copyWith(isLoading: true, searchQuery: query, error: null);
    
    try {
      if (query.isEmpty) {
        await loadDiaries();
        return;
      }
      
      final diaries = await _databaseService.searchDiaries(query);
      state = state.copyWith(isLoading: false, diaries: diaries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 按标签筛选
  Future<void> filterByTag(String? tag) async {
    state = state.copyWith(isLoading: true, selectedTag: tag, error: null);
    
    try {
      if (tag == null) {
        await loadDiaries();
        return;
      }
      
      final diaries = await _databaseService.getDiariesByTag(tag);
      state = state.copyWith(isLoading: false, diaries: diaries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    await loadDiaries();
  }
}

/// 日记列表 Provider
final diaryListProvider = StateNotifierProvider<DiaryListNotifier, DiaryListState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider).valueOrNull;
  if (databaseService == null) {
    throw StateError('Database not initialized');
  }
  return DiaryListNotifier(databaseService);
});

/// 当前编辑的日记 Provider
final currentDiaryProvider = StateProvider<DiaryEntry?>((ref) => null);

/// 标签列表 Provider
final tagsProvider = FutureProvider<Set<String>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider).valueOrNull;
  if (databaseService == null) {
    return {};
  }
  return await databaseService.getAllTags();
});

/// 日记操作服务
class DiaryService {
  final DatabaseService _databaseService;
  final GistService _gistService;
  final AuthService _authService;
  final Ref _ref;

  DiaryService(this._databaseService, this._gistService, this._authService, this._ref);

  /// 创建日记
  Future<DiaryEntry> createDiary({
    String? title,
    required String content,
    int moodIndex = 7,
    int? weatherIndex,
    List<String> tags = const [],
    List<String> images = const [],
    String? location,
  }) async {
    final entry = DiaryEntry()
      ..title = title
      ..content = content
      ..moodIndex = moodIndex
      ..weatherIndex = weatherIndex
      ..tags = tags
      ..images = images
      ..location = location;

    await _databaseService.saveDiary(entry);
    _triggerAutoSync();
    return entry;
  }

  /// 更新日记
  Future<void> updateDiary(DiaryEntry entry) async {
    await _databaseService.saveDiary(entry);
    _triggerAutoSync();
  }

  /// 删除日记
  Future<void> deleteDiary(int id) async {
    await _databaseService.deleteDiary(id);
    _triggerAutoSync();
  }

  /// 永久删除日记
  Future<void> permanentlyDeleteDiary(int id) async {
    await _databaseService.permanentlyDeleteDiary(id);
    _triggerAutoSync();
  }

  /// 触发自动同步
  void _triggerAutoSync() {
    _ref.read(syncStateProvider.notifier).onDiaryChanged();
  }

  /// 导出日记为 JSON
  Future<String> exportToJson(List<DiaryEntry> entries) async {
    final jsonList = entries.map((e) => e.toJson()).toList();
    return const JsonEncoder().convert(jsonList);
  }

  /// 导出日记为 Markdown
  Future<String> exportToMarkdown(List<DiaryEntry> entries) async {
    final buffer = StringBuffer();
    
    for (final entry in entries) {
      buffer.writeln('# ${entry.title ?? "无标题"}');
      buffer.writeln();
      buffer.writeln('> ${entry.createdAt.toString().split('.')[0]}');
      buffer.writeln();
      if (entry.tags.isNotEmpty) {
        buffer.writeln('标签: ${entry.tags.join(", ")}');
        buffer.writeln();
      }
      buffer.writeln(entry.content);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  /// 从 JSON 导入日记
  Future<List<DiaryEntry>> importFromJson(String jsonString) async {
    final List<dynamic> jsonList = const JsonDecoder().convert(jsonString);
    final entries = <DiaryEntry>[];
    
    for (final json in jsonList) {
      final entry = DiaryEntry.fromJson(json);
      entries.add(entry);
      await _databaseService.saveDiary(entry);
    }
    
    return entries;
  }
}

/// 日记服务 Provider
final diaryServiceProvider = Provider<DiaryService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider).valueOrNull;
  final gistService = ref.watch(gistServiceProvider);
  final authService = ref.watch(authServiceProvider);

  if (databaseService == null) {
    throw StateError('Database not initialized');
  }

  return DiaryService(databaseService, gistService, authService, ref);
});

