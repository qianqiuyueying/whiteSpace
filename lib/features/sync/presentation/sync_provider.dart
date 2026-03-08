import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/gist_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/data/models/user_profile.dart';
import '../../diary/data/models/diary_entry.dart';

/// 同步状态
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// 同步结果
class SyncResult {
  final bool success;
  final int uploadedCount;
  final int downloadedCount;
  final String? error;

  const SyncResult({
    required this.success,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.error,
  });
}

/// 同步服务
class SyncService {
  final DatabaseService _databaseService;
  final GistService _gistService;
  final AuthService _authService;

  SyncService(this._databaseService, this._gistService, this._authService);

  /// 执行完整同步
  Future<SyncResult> sync() async {
    try {
      // 1. 获取或创建 Gist
      String? gistId = await _authService.getGistId();
      
      if (gistId == null) {
        // 创建新的 Gist
        gistId = await _createGist();
        await _authService.saveGistId(gistId);
      }

      // 2. 从云端获取数据
      final gist = await _gistService.getGist(gistId);
      if (gist == null) {
        // Gist 不存在，创建新的
        gistId = await _createGist();
        await _authService.saveGistId(gistId);
        return const SyncResult(success: true);
      }

      // 3. 解析云端数据
      final cloudDiaries = await _parseGistFiles(gist['files'] as Map<String, dynamic>);

      // 4. 获取本地数据
      final localDiaries = await _databaseService.getAllDiaries(includeDeleted: true);

      // 5. 合并数据
      final mergeResult = await _mergeDiaries(localDiaries, cloudDiaries);

      // 6. 更新 Gist
      await _updateGist(gistId, mergeResult.allDiaries);

      // 7. 更新同步时间
      await _databaseService.updateLastSyncTime();

      return SyncResult(
        success: true,
        uploadedCount: mergeResult.uploadedCount,
        downloadedCount: mergeResult.downloadedCount,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 创建新的 Gist
  Future<String> _createGist() async {
    final diaries = await _databaseService.getAllDiaries();
    final files = <String, String>{};
    
    // 创建配置文件
    files[AppConstants.configFile] = jsonEncode({
      'version': '1.0',
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    // 创建标签文件
    final tags = await _databaseService.getAllTags();
    files[AppConstants.tagsFile] = jsonEncode(tags.toList());
    
    // 添加日记文件
    for (final diary in diaries) {
      final fileName = '${AppConstants.diaryFilePrefix}${diary.uuid}.json';
      files[fileName] = jsonEncode(diary.toJson());
    }

    final result = await _gistService.createGist(
      description: '留白日记 - 数据同步',
      files: files,
      isPublic: false,
    );

    return result['id'] as String;
  }

  /// 更新 Gist
  Future<void> _updateGist(String gistId, List<DiaryEntry> diaries) async {
    final files = <String, String>{};
    
    // 更新标签文件
    final tags = await _databaseService.getAllTags();
    files[AppConstants.tagsFile] = jsonEncode(tags.toList());
    
    // 更新日记文件
    for (final diary in diaries) {
      if (!diary.isDeleted) {
        final fileName = '${AppConstants.diaryFilePrefix}${diary.uuid}.json';
        files[fileName] = jsonEncode(diary.toJson());
      }
    }

    await _gistService.updateGist(gistId: gistId, files: files);
  }

  /// 解析 Gist 文件
  Future<List<DiaryEntry>> _parseGistFiles(Map<String, dynamic> files) async {
    final diaries = <DiaryEntry>[];
    
    for (final entry in files.entries) {
      if (entry.key.startsWith(AppConstants.diaryFilePrefix)) {
        try {
          final content = entry.value['content'] as String;
          final json = jsonDecode(content) as Map<String, dynamic>;
          diaries.add(DiaryEntry.fromJson(json));
        } catch (e) {
          // 忽略解析错误的文件
        }
      }
    }
    
    return diaries;
  }

  /// 合并日记数据
  Future<_MergeResult> _mergeDiaries(
    List<DiaryEntry> localDiaries,
    List<DiaryEntry> cloudDiaries,
  ) async {
    final result = _MergeResult();
    final allDiaries = <String, DiaryEntry>{};
    
    // 建立云端数据索引
    for (final cloud in cloudDiaries) {
      allDiaries[cloud.uuid] = cloud;
    }
    
    // 处理本地数据
    for (final local in localDiaries) {
      final cloud = allDiaries[local.uuid];
      
      if (cloud == null) {
        // 云端没有，需要上传
        result.uploadedCount++;
        allDiaries[local.uuid] = local;
      } else if (local.updatedAt.isAfter(cloud.updatedAt)) {
        // 本地更新，需要上传
        result.uploadedCount++;
        allDiaries[local.uuid] = local;
      } else if (cloud.updatedAt.isAfter(local.updatedAt)) {
        // 云端更新，需要下载
        result.downloadedCount++;
        await _databaseService.saveDiary(cloud);
        allDiaries[local.uuid] = cloud;
      } else {
        // 相同，保持本地
        allDiaries[local.uuid] = local;
      }
    }
    
    // 处理云端新增的数据
    for (final cloud in cloudDiaries) {
      if (!allDiaries.containsKey(cloud.uuid)) {
        result.downloadedCount++;
        await _databaseService.saveDiary(cloud);
        allDiaries[cloud.uuid] = cloud;
      }
    }
    
    result.allDiaries = allDiaries.values.toList();
    return result;
  }

  /// 强制上传所有数据
  Future<SyncResult> forceUpload() async {
    try {
      String? gistId = await _authService.getGistId();
      
      if (gistId == null) {
        gistId = await _createGist();
        await _authService.saveGistId(gistId);
      } else {
        final diaries = await _databaseService.getAllDiaries();
        await _updateGist(gistId, diaries);
      }

      await _databaseService.updateLastSyncTime();
      return const SyncResult(success: true);
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 强制下载所有数据
  Future<SyncResult> forceDownload() async {
    try {
      final gistId = await _authService.getGistId();
      if (gistId == null) {
        return const SyncResult(success: false, error: '未找到同步数据');
      }

      final gist = await _gistService.getGist(gistId);
      if (gist == null) {
        return const SyncResult(success: false, error: '云端数据不存在');
      }

      final cloudDiaries = await _parseGistFiles(gist['files'] as Map<String, dynamic>);
      
      // 清除本地数据
      // TODO: 实现清除逻辑
      
      // 保存云端数据
      for (final diary in cloudDiaries) {
        await _databaseService.saveDiary(diary);
      }

      await _databaseService.updateLastSyncTime();
      return SyncResult(
        success: true,
        downloadedCount: cloudDiaries.length,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }
}

/// 合并结果
class _MergeResult {
  List<DiaryEntry> allDiaries = [];
  int uploadedCount = 0;
  int downloadedCount = 0;
}

/// 同步服务 Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider).valueOrNull;
  final gistService = ref.watch(gistServiceProvider);
  final authService = ref.watch(authServiceProvider);
  
  if (databaseService == null) {
    throw StateError('Database not initialized');
  }
  
  return SyncService(databaseService, gistService, authService);
});

/// 同步状态 Provider
final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);