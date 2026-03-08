import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/database_service.dart';
import '../../../core/services/gist_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/app_constants.dart';
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

/// 同步状态管理
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncAt;
  final String? errorMessage;
  final bool autoSyncEnabled;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncAt,
    this.errorMessage,
    this.autoSyncEnabled = true,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    String? errorMessage,
    bool? autoSyncEnabled,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: errorMessage,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
    );
  }
}

/// 同步状态管理器
class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;
  Timer? _autoSyncTimer;
  static const Duration _autoSyncInterval = Duration(minutes: 5);

  SyncNotifier(this._syncService) : super(const SyncState()) {
    _startAutoSync();
  }

  /// 启动自动同步定时器
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      if (state.autoSyncEnabled && state.status != SyncStatus.syncing) {
        sync();
      }
    });
  }

  /// 手动触发同步
  Future<SyncResult> sync() async {
    if (state.status == SyncStatus.syncing) {
      return const SyncResult(success: false, error: '正在同步中');
    }

    state = state.copyWith(status: SyncStatus.syncing, errorMessage: null);

    final result = await _syncService.sync();

    if (result.success) {
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncAt: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: result.error,
      );
    }

    return result;
  }

  /// 日记变更后触发同步
  Future<void> onDiaryChanged() async {
    if (state.autoSyncEnabled && state.status != SyncStatus.syncing) {
      // 延迟 3 秒后同步，避免频繁触发
      await Future.delayed(const Duration(seconds: 3));
      if (state.autoSyncEnabled && state.status != SyncStatus.syncing) {
        await sync();
      }
    }
  }

  /// 切换自动同步
  void toggleAutoSync(bool enabled) {
    state = state.copyWith(autoSyncEnabled: enabled);
    if (enabled) {
      _startAutoSync();
    } else {
      _autoSyncTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
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
        // 本地没有 gistId，先从云端搜索现有的同步 Gist
        gistId = await _findExistingGist();
        if (gistId != null) {
          // 找到现有的 Gist，保存到本地
          await _authService.saveGistId(gistId);
        }
      }

      if (gistId == null) {
        // 仍然没有，创建新的 Gist
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

      // 3. 解析云端数据（包含日记和标签）
      final parseResult = await _parseGistFiles(gist['files'] as Map<String, dynamic>);
      final cloudDiaries = parseResult.diaries;

      // 4. 获取本地数据
      final localDiaries = await _databaseService.getAllDiaries(includeDeleted: true);

      // 5. 合并数据（带冲突检测）
      final mergeResult = await _mergeDiaries(localDiaries, cloudDiaries);

      // 6. 更新 Gist（包含需要删除的文件，并清理云端残留）
      await _updateGist(
        gistId,
        mergeResult.allDiaries,
        deletedUuids: mergeResult.deletedUuids,
        cloudFiles: gist['files'] as Map<String, dynamic>?,
      );

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

  /// 搜索用户现有的同步 Gist
  /// 用于多设备同步：新设备可以从云端找到已有的 Gist
  Future<String?> _findExistingGist() async {
    try {
      final gists = await _gistService.getGists();
      for (final gist in gists) {
        if (gist['description'] == '留白日记 - 数据同步') {
          return gist['id'] as String;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 更新 Gist
  /// [cloudFiles] 云端现有文件列表，用于清理云端残留文件
  Future<void> _updateGist(
    String gistId,
    List<DiaryEntry> diaries, {
    List<String> deletedUuids = const [],
    Map<String, dynamic>? cloudFiles,
  }) async {
    final files = <String, String?>{};

    // 更新标签文件
    final tags = await _databaseService.getAllTags();
    files[AppConstants.tagsFile] = jsonEncode(tags.toList());

    // 本地有效的日记UUID集合
    final localUuids = <String>{};

    // 更新日记文件
    for (final diary in diaries) {
      if (!diary.isDeleted) {
        final fileName = '${AppConstants.diaryFilePrefix}${diary.uuid}.json';
        files[fileName] = jsonEncode(diary.toJson());
        localUuids.add(diary.uuid);
      }
    }

    // 删除云端已删除的日记文件
    for (final uuid in deletedUuids) {
      final fileName = '${AppConstants.diaryFilePrefix}$uuid.json';
      files[fileName] = null; // 设置为 null 表示删除文件
    }

    // 清理云端残留文件：云端有但本地没有的日记文件
    if (cloudFiles != null) {
      for (final fileName in cloudFiles.keys) {
        if (fileName.startsWith(AppConstants.diaryFilePrefix)) {
          // 提取UUID
          final uuid = fileName
              .replaceFirst(AppConstants.diaryFilePrefix, '')
              .replaceAll('.json', '');
          // 如果本地没有这个UUID，删除云端文件
          if (!localUuids.contains(uuid) && !deletedUuids.contains(uuid)) {
            files[fileName] = null;
          }
        }
      }
    }

    await _gistService.updateGist(gistId: gistId, files: files);
  }

  /// 解析 Gist 文件
  Future<_GistParseResult> _parseGistFiles(Map<String, dynamic> files) async {
    final result = _GistParseResult();

    for (final entry in files.entries) {
      try {
        final content = entry.value['content'] as String;
        
        if (entry.key.startsWith(AppConstants.diaryFilePrefix)) {
          // 解析日记文件
          final json = jsonDecode(content) as Map<String, dynamic>;
          result.diaries.add(DiaryEntry.fromJson(json));
        } else if (entry.key == AppConstants.tagsFile) {
          // 解析标签文件
          final List<dynamic> tagsJson = jsonDecode(content);
          for (final tagJson in tagsJson) {
            if (tagJson is Map<String, dynamic>) {
              result.tags.add(tagJson['name'] as String);
            } else if (tagJson is String) {
              result.tags.add(tagJson);
            }
          }
        }
      } catch (e) {
        // 忽略解析错误的文件
      }
    }

    return result;
  }

  /// 合并日记数据（带冲突检测）
  Future<_MergeResult> _mergeDiaries(
    List<DiaryEntry> localDiaries,
    List<DiaryEntry> cloudDiaries,
  ) async {
    final result = _MergeResult();
    final allDiaries = <String, DiaryEntry>{};

    // 建立云端数据索引
    final cloudDiariesMap = <String, DiaryEntry>{};
    for (final cloud in cloudDiaries) {
      cloudDiariesMap[cloud.uuid] = cloud;
    }

    // 处理本地数据
    for (final local in localDiaries) {
      final cloud = cloudDiariesMap[local.uuid];

      if (cloud == null) {
        // 云端没有此日记
        if (local.isDeleted) {
          // 本地已删除且云端没有，跳过（不需要上传）
          continue;
        }
        // 本地有但云端没有，需要上传
        result.uploadedCount++;
        allDiaries[local.uuid] = local;
      } else if (cloud.isDeleted) {
        // 云端已删除，本地也应该删除
        if (!local.isDeleted) {
          await _databaseService.deleteDiary(local.id);
        }
        // 记录需要从云端删除的 UUID
        result.deletedUuids.add(cloud.uuid);
      } else if (local.isDeleted) {
        // 本地已删除但云端未删除
        // 以最新的为准
        if (local.updatedAt.isAfter(cloud.updatedAt)) {
          // 本地删除操作更新，需要从云端删除
          result.deletedUuids.add(local.uuid);
        } else {
          // 云端更新，恢复本地日记
          result.downloadedCount++;
          await _databaseService.saveDiary(cloud);
          allDiaries[local.uuid] = cloud;
        }
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
      if (!allDiaries.containsKey(cloud.uuid) && !cloud.isDeleted) {
        // 本地没有且云端未删除，需要下载
        final localExists = localDiaries.any((d) => d.uuid == cloud.uuid);
        if (!localExists) {
          result.downloadedCount++;
          await _databaseService.saveDiary(cloud);
        }
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
        // 获取云端现有文件，用于清理残留
        final gist = await _gistService.getGist(gistId);
        final cloudFiles = gist?['files'] as Map<String, dynamic>?;

        final diaries = await _databaseService.getAllDiaries();
        await _updateGist(gistId, diaries, cloudFiles: cloudFiles);
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

      final parseResult = await _parseGistFiles(gist['files'] as Map<String, dynamic>);
      final cloudDiaries = parseResult.diaries;

      // 保存云端数据（跳过已删除的）
      int downloadedCount = 0;
      for (final diary in cloudDiaries) {
        if (!diary.isDeleted) {
          await _databaseService.saveDiary(diary);
          downloadedCount++;
        }
      }

      await _databaseService.updateLastSyncTime();
      return SyncResult(
        success: true,
        downloadedCount: downloadedCount,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 立即从云端删除日记文件
  /// 用于本地删除日记后立即同步删除云端文件
  Future<bool> deleteDiaryFromCloud(String uuid) async {
    try {
      final gistId = await _authService.getGistId();
      if (gistId == null) {
        return false;
      }

      final fileName = '${AppConstants.diaryFilePrefix}$uuid.json';
      await _gistService.updateGist(gistId: gistId, files: {fileName: null});
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 合并结果
class _MergeResult {
  List<DiaryEntry> allDiaries = [];
  List<String> deletedUuids = []; // 需要从云端删除的日记 UUID
  int uploadedCount = 0;
  int downloadedCount = 0;
}

/// Gist 解析结果
class _GistParseResult {
  List<DiaryEntry> diaries = [];
  Set<String> tags = {};
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
final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncNotifier(syncService);
});