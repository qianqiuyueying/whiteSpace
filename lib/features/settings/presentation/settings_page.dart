import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// 
/// 设计理念：清晰的分组，优雅的卡片，舒适的阅读体验
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.accentColor),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      final db = await ref.read(databaseServiceProvider.future);
      await db.close();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _exportData() async {
    try {
      final db = await ref.read(databaseServiceProvider.future);
      final diaries = await db.getAllDiaries();

      if (diaries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('没有日记可导出'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
            ),
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
        await Share.shareXFiles([XFile(file.path)], subject: '日记导出');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 ${importResult.count} 篇日记'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
          ),
        );
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
      final result = await ref.read(syncServiceProvider).sync();

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('同步成功，上传 ${result.uploadedCount} 篇，下载 ${result.downloadedCount} 篇'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
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
      if (mounted) setState(() => _isSyncing = false);
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildUserCard(user, isDark),
                      const SizedBox(height: 32),
                      _buildSection('数据同步', [
                        _buildSyncTile(isDark),
                        _buildListTile(
                          icon: Icons.open_in_new_rounded,
                          title: '查看 Gist',
                          subtitle: '在浏览器中查看云端数据',
                          onTap: _openGistPage,
                          isDark: isDark,
                        ),
                        _buildListTile(
                          icon: Icons.history_rounded,
                          title: '上次同步',
                          subtitle: user?.lastSyncAt != null
                              ? _formatDateTime(user!.lastSyncAt!)
                              : '从未同步',
                          isDark: isDark,
                        ),
                      ], isDark),
                      const SizedBox(height: 24),
                      _buildSection('个人', [
                        _buildListTile(
                          icon: Icons.flag_outlined,
                          title: '写作目标',
                          subtitle: '设置每日/每周写作目标',
                          onTap: () => context.push('/goals'),
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
                        _buildThemeTile(isDark),
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
                      _buildLogoutButton(isDark),
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
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          Text(
            '设置',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              letterSpacing: -0.5,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: user?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      user!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 28,
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
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'GitHub 账号已连接',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '已连接',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            children: _insertDividers(children, isDark),
          ),
        ),
      ],
    );
  }

  List<Widget> _insertDividers(List<Widget> children, bool isDark) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(Divider(
          height: 1,
          indent: 56,
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ));
      }
    }
    return result;
  }

  Widget _buildSyncTile(bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
              .withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isSyncing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
              )
            : Icon(
                Icons.sync_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                size: 20,
              ),
      ),
      title: Text(
        '立即同步',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
        ),
      ),
      subtitle: Text(
        '同步到 GitHub Gist',
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark
            ? AppTheme.darkTextTertiary
            : AppTheme.lightTextTertiary,
      ),
      onTap: _isSyncing ? null : _syncNow,
    );
  }

  Widget _buildThemeTile(bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
              .withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.dark_mode_outlined,
          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        '深色模式',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
        ),
      ),
      subtitle: Text(
        '跟随系统',
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
      trailing: Switch(
        value: _isDarkMode,
        onChanged: (value) => setState(() => _isDarkMode = value),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
              .withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
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
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppTheme.darkTextTertiary
                  : AppTheme.lightTextTertiary,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accentColor,
          side: BorderSide(
            color: AppTheme.accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}