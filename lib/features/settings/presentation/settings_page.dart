import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/auth_service.dart';
import '../../sync/presentation/sync_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/data/models/user_profile.dart';
import '../../diary/presentation/diary_provider.dart';

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isDarkMode = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // TODO: 从本地存储加载主题设置
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？本地数据将被清除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      final db = await ref.read(databaseServiceProvider.future);
      await db.close();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final db = await ref.read(databaseServiceProvider.future);
      final diaries = await db.getAllDiaries();

      if (diaries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有日记可导出')),
          );
        }
        return;
      }

      final diaryService = ref.read(diaryServiceProvider);
      final json = await diaryService.exportToJson(diaries);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/diary_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: '日记导出',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt', 'md'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final fileName = result.files.first.name;

      final importService = ref.read(importServiceProvider);
      final importResult = await importService.autoImport(content, fileName);

      ref.read(diaryListProvider.notifier).refresh();

      if (mounted) {
        if (importResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功导入 ${importResult.count} 篇日记'),
              action: importResult.errors.isNotEmpty
                  ? SnackBarAction(
                      label: '查看详情',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('导入详情'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: importResult.errors
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(e),
                                        ))
                                    .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('确定'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('导入失败: ${importResult.errors.first}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);

    try {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.sync();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('同步成功！上传 ${result.uploadedCount} 篇，下载 ${result.downloadedCount} 篇'),
              action: SnackBarAction(
                label: '查看 Gist',
                onPressed: _openGistPage,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('同步失败: ${result.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('同步失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _openGistPage() async {
    final gistId = await ref.read(authServiceProvider).getGistId();
    if (gistId != null) {
      final uri = Uri.parse('https://gist.github.com/$gistId');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('尚未创建同步数据，请先同步')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.darkBackground, AppTheme.darkSurface]
                : [AppTheme.lightBackground, AppTheme.lightSurface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildUserCard(user, isDark),
                      const SizedBox(height: 24),
                      _buildSection('数据同步', [
                        _buildListTile(
                          icon: Icons.sync_rounded,
                          title: '立即同步',
                          subtitle: '同步到 GitHub Gist',
                          trailing: _isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: _isSyncing ? null : _syncNow,
                          isDark: isDark,
                        ),
                        _buildListTile(
                          icon: Icons.open_in_new_rounded,
                          title: '查看 Gist',
                          subtitle: '在浏览器中查看云端数据',
                          onTap: _openGistPage,
                          isDark: isDark,
                        ),
                        _buildListTile(
                          icon: Icons.cloud_done_rounded,
                          title: '上次同步',
                          subtitle: user?.lastSyncAt != null
                              ? _formatDateTime(user!.lastSyncAt!)
                              : '从未同步',
                          isDark: isDark,
                        ),
                      ], isDark),
                      const SizedBox(height: 24),
                      _buildSection('数据管理', [
                        _buildListTile(
                          icon: Icons.delete_outline_rounded,
                          title: '回收站',
                          subtitle: '查看已删除的日记',
                          onTap: () => context.push('/trash'),
                          isDark: isDark,
                        ),
                        _buildListTile(
                          icon: Icons.upload_file_rounded,
                          title: '导出日记',
                          subtitle: '导出为 JSON 格式',
                          onTap: _exportData,
                          isDark: isDark,
                        ),
                        _buildListTile(
                          icon: Icons.download_rounded,
                          title: '导入日记',
                          subtitle: '支持 JSON、Markdown、纯文本',
                          onTap: _importData,
                          isDark: isDark,
                        ),
                      ], isDark),
                      const SizedBox(height: 24),
                      _buildSection('外观', [
                        _buildListTile(
                          icon: Icons.dark_mode_rounded,
                          title: '深色模式',
                          subtitle: '跟随系统',
                          trailing: Switch(
                            value: _isDarkMode,
                            onChanged: (value) {
                              setState(() => _isDarkMode = value);
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          isDark: isDark,
                        ),
                      ], isDark),
                      const SizedBox(height: 24),
                      _buildSection('关于', [
                        _buildListTile(
                          icon: Icons.info_outline_rounded,
                          title: '版本',
                          subtitle: AppConstants.appVersion,
                          isDark: isDark,
                        ),
                        _buildListTile(
                          icon: Icons.code_rounded,
                          title: '开源许可',
                          onTap: () {
                            showLicensePage(
                              context: context,
                              applicationName: AppConstants.appName,
                              applicationVersion: AppConstants.appVersion,
                            );
                          },
                          isDark: isDark,
                        ),
                      ], isDark),
                      const SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            '退出登录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          Text(
            '设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile? user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: user?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      user!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.username ?? '未登录',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GitHub 账号已连接',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '已连接',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            )
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}