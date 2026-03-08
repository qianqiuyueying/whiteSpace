import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/diary/data/models/diary_entry.dart';
import '../../features/auth/data/models/user_profile.dart';

/// 数据库服务
class DatabaseService {
  static DatabaseService? _instance;
  static Isar? _isar;

  DatabaseService._();

  /// 获取单例实例
  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// 初始化数据库
  Future<void> _init() async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [DiaryEntrySchema, UserProfileSchema],
      directory: dir.path,
      inspector: true,
    );
  }

  /// 获取 Isar 实例
  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError('Database not initialized. Call getInstance() first.');
    }
    return _isar!;
  }

  /// 关闭数据库
  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  // ==================== 日记相关操作 ====================

  /// 获取所有日记
  Future<List<DiaryEntry>> getAllDiaries({
    bool includeDeleted = false,
    bool sortByUpdateTime = true,
  }) async {
    if (includeDeleted) {
      if (sortByUpdateTime) {
        return isar.diaryEntrys.where().sortByUpdatedAtDesc().findAll();
      }
      return isar.diaryEntrys.where().findAll();
    }
    
    if (sortByUpdateTime) {
      return isar.diaryEntrys
          .filter()
          .isDeletedEqualTo(false)
          .sortByUpdatedAtDesc()
          .findAll();
    }
    return isar.diaryEntrys
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }

  /// 根据 ID 获取日记
  Future<DiaryEntry?> getDiaryById(int id) async {
    return isar.diaryEntrys.get(id);
  }

  /// 根据 UUID 获取日记
  Future<DiaryEntry?> getDiaryByUuid(String uuid) async {
    return isar.diaryEntrys.where().uuidEqualTo(uuid).findFirst();
  }

  /// 保存日记
  Future<int> saveDiary(DiaryEntry entry) async {
    entry.updatedAt = DateTime.now();
    return isar.writeTxn(() => isar.diaryEntrys.put(entry));
  }

  /// 批量保存日记
  Future<void> saveDiaries(List<DiaryEntry> entries) async {
    await isar.writeTxn(() async {
      for (final entry in entries) {
        entry.updatedAt = DateTime.now();
        await isar.diaryEntrys.put(entry);
      }
    });
  }

  /// 删除日记 (软删除)
  Future<void> deleteDiary(int id) async {
    final entry = await getDiaryById(id);
    if (entry != null) {
      entry.isDeleted = true;
      entry.updatedAt = DateTime.now();
      await saveDiary(entry);
    }
  }

  /// 永久删除日记
  Future<void> permanentlyDeleteDiary(int id) async {
    await isar.writeTxn(() => isar.diaryEntrys.delete(id));
  }

  /// 获取未同步的日记
  Future<List<DiaryEntry>> getUnsyncedDiaries() async {
    return isar.diaryEntrys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  /// 搜索日记
  Future<List<DiaryEntry>> searchDiaries(String query) async {
    final lowerQuery = query.toLowerCase();
    return isar.diaryEntrys
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .group((q) => q
            .titleContains(lowerQuery, caseSensitive: false)
            .or()
            .contentContains(lowerQuery, caseSensitive: false))
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 根据标签获取日记
  Future<List<DiaryEntry>> getDiariesByTag(String tag) async {
    return isar.diaryEntrys
        .filter()
        .isDeletedEqualTo(false)
        .and()
        .tagsElementEqualTo(tag)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  /// 获取所有标签
  Future<Set<String>> getAllTags() async {
    final diaries = await getAllDiaries();
    final tags = <String>{};
    for (final diary in diaries) {
      tags.addAll(diary.tags);
    }
    return tags;
  }

  // ==================== 用户相关操作 ====================

  /// 获取当前用户
  Future<UserProfile?> getCurrentUser() async {
    return isar.userProfiles.where().findFirst();
  }

  /// 保存用户
  Future<int> saveUser(UserProfile user) async {
    return isar.writeTxn(() => isar.userProfiles.put(user));
  }

  /// 删除用户
  Future<void> deleteUser() async {
    await isar.writeTxn(() => isar.userProfiles.clear());
  }

  /// 更新同步时间
  Future<void> updateLastSyncTime() async {
    final user = await getCurrentUser();
    if (user != null) {
      user.lastSyncAt = DateTime.now();
      await saveUser(user);
    }
  }
}

/// 数据库服务 Provider
final databaseServiceProvider = FutureProvider<DatabaseService>((ref) async {
  return await DatabaseService.getInstance();
});