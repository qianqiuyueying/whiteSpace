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
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/version_service.dart';
import '../../sync/presentation/sync_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/data/models/user_profile.dart';
import '../../diary/presentation/diary_provider.dart';
import '../../../shared/widgets/update_dialog.dart';

/// 设置页面
///
/// 设计理念：清晰的分组，优雅的卡片，舒适的阅读体验
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSyncing = false;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
  }

  /// 检查更新
  Future<void> _checkForUpdate() async {
    setState(() => _isCheckingUpdate = true);

    try {
      final versionInfo = await VersionService.checkForUpdates();

      if (!mounted) return;

      if (versionInfo != null) {
        // 有新版本，显示更新弹窗
        await showUpdateDialog(
          context: context,
          versionInfo: versionInfo,
          isDark: Theme.of(context).brightness == Brightness.dark,
        );
      } else {
        // 已是最新版本
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('已是最新版本，无需更新'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              ),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('检查更新失败：$e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  Future<void> _unbindToken() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解绑 GitHub Token'),
        content: const Text('确定要解绑吗？解绑后将无法使用云同步功能，本地数据不会丢失。'),
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
            child: const Text('解绑'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).unbindToken();
    }
  }

  Future<void> _showBindTokenDialog(bool isDark) async {
    final tokenController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureText = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('绑定 GitHub Token'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '绑定后可使用云同步功能',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tokenController,
                    obscureText: obscureText,
                    style: TextStyle(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                      hintStyle: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextTertiary
                            : AppTheme.lightTextTertiary,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: isDark
                              ? AppTheme.darkTextTertiary
                              : AppTheme.lightTextTertiary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入 GitHub Token';
                      }
                      if (value.length < 35) {
                        return 'Token 格式不正确';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://github.com/settings/tokens/new?description=留白日记&scopes=gist',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    ),
                    label: Text(
                      '获取 Token',
                      style: TextStyle(
                        color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context);
                
                final success = await ref
                    .read(authProvider.notifier)
                    .bindToken(tokenController.text.trim());

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('绑定成功'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                        ),
                      ),
                    );
                    // 绑定成功后自动同步一次
                    ref.read(syncServiceProvider).sync();
                  } else {
                    final error = ref.read(authProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('绑定失败: ${error ?? "未知错误"}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('绑定'),
            ),
          ],
        ),
      ),
    );
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
          // 刷新日记列表
          ref.read(diaryListProvider.notifier).refresh();
          
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
    final isBound = authState.isBound;

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
                      _buildUserCard(user, isBound, isDark),
                      const SizedBox(height: 32),
                      if (isBound) ...[
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
                      ] else ...[
                        _buildSection('云同步', [
                          _buildListTile(
                            icon: Icons.link_rounded,
                            title: '绑定 GitHub Token',
                            subtitle: '绑定后可使用云同步功能',
                            onTap: () => _showBindTokenDialog(isDark),
                            isDark: isDark,
                          ),
                        ], isDark),
                      ],
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
                          icon: Icons.system_update_rounded,
                          title: '检查更新',
                          subtitle: '当前版本 ${AppConstants.appVersion}',
                          onTap: _checkForUpdate,
                          isDark: isDark,
                          trailing: _isCheckingUpdate
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                        ),
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
                      if (isBound) _buildUnbindButton(isDark),
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

  Widget _buildUserCard(UserProfile? user, bool isBound, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isBound ? AppTheme.primaryGradient : null,
        color: isBound ? null : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: isBound ? null : Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: isBound
            ? [
                BoxShadow(
                  color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isBound
                  ? Colors.white.withValues(alpha: 0.2)
                  : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
              borderRadius: BorderRadius.circular(16),
            ),
            child: isBound && user?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      user!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person_outline_rounded,
                        color: isBound ? Colors.white : (isDark ? AppTheme.darkText : AppTheme.lightText),
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    isBound ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: isBound ? Colors.white : (isDark ? AppTheme.darkText : AppTheme.lightText),
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBound ? (user?.username ?? '已绑定') : '本地模式',
                  style: TextStyle(
                    color: isBound ? Colors.white : (isDark ? AppTheme.darkText : AppTheme.lightText),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBound ? 'GitHub 账号已连接' : '数据仅保存在本地',
                  style: TextStyle(
                    color: isBound
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (isBound)
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
    final themeState = ref.watch(themeProvider);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
              .withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          themeState.mode == AppThemeMode.dark 
              ? Icons.dark_mode_rounded 
              : themeState.mode == AppThemeMode.light
                  ? Icons.light_mode_rounded
                  : Icons.brightness_auto_rounded,
          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        '外观模式',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
        ),
      ),
      subtitle: Text(
        themeState.mode.label,
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
      onTap: () => _showThemeDialog(isDark),
    );
  }

  void _showThemeDialog(bool isDark) {
    final themeState = ref.read(themeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择外观模式'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((mode) {
            final isSelected = themeState.mode == mode;
            return RadioListTile<AppThemeMode>(
              title: Text(mode.label),
              value: mode,
              groupValue: themeState.mode,
              selected: isSelected,
              activeColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required bool isDark,
    Widget? trailing,
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
      trailing: trailing ?? (onTap != null
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

  Widget _buildUnbindButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _unbindToken,
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
          '解绑 GitHub Token',
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