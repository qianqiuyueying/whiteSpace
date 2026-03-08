import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/services/version_service.dart';

/// 显示更新弹窗
///
/// 参数：
/// - [context] BuildContext
/// - [versionInfo] 新版本信息
/// - [isDark] 是否为深色模式
///
/// 返回：用户是否点击了"立即更新"
Future<bool> showUpdateDialog({
  required BuildContext context,
  required VersionInfo versionInfo,
  required bool isDark,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => UpdateDialog(
      versionInfo: versionInfo,
      isDark: isDark,
    ),
  );
  
  return result == true;
}

/// 更新提示弹窗
///
/// 设计理念：清晰展示更新内容，引导用户升级
class UpdateDialog extends StatelessWidget {
  final VersionInfo versionInfo;
  final bool isDark;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
            color: isDark
                ? AppTheme.darkBorder
                : AppTheme.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部装饰区域
            _buildHeader(context),
            
            const SizedBox(height: 24),
            
            // 版本信息
            _buildVersionInfo(context),
            
            const SizedBox(height: 16),
            
            // 更新说明
            _buildReleaseNotes(context),
            
            const SizedBox(height: 24),
            
            // 操作按钮
            _buildActions(context),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).animate().scale(duration: 250.ms, curve: Curves.easeOut).fadeIn();
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXL),
          topRight: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      child: Column(
        children: [
          // 更新图标
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 标题
          Text(
            '发现新版本',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 发布时间
          Text(
            '发布于 ${DateFormat('yyyy 年 MM 月 dd 日').format(versionInfo.publishedAt)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 当前版本
          _buildVersionBadge(
            label: '当前版本',
            version: versionInfo.version,
            isCurrent: true,
          ),
          
          const SizedBox(width: 16),
          
          // 箭头
          Icon(
            Icons.arrow_forward_rounded,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            size: 20,
          ),
          
          const SizedBox(width: 16),
          
          // 新版本
          _buildVersionBadge(
            label: '最新版本',
            version: versionInfo.version,
            isCurrent: false,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionBadge({
    required String label,
    required String version,
    required bool isCurrent,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrent
                ? (isDark ? AppTheme.darkSurface : AppTheme.lightSurface)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: isCurrent
                  ? (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                  : AppTheme.primaryColor,
              width: 1.5,
            ),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isCurrent
                  ? (isDark ? AppTheme.darkText : AppTheme.lightText)
                  : AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseNotes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.new_releases_rounded,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '更新内容',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 更新说明内容
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 1,
              ),
            ),
            child: SingleChildScrollView(
              child: Text(
                versionInfo.releaseNotes,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // 稍后再说按钮
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  side: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                '稍后再说',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 立即更新按钮
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // 关闭弹窗
                Navigator.pop(context, true);
                
                // 打开下载链接
                if (versionInfo.downloadUrl.isNotEmpty) {
                  final url = Uri.parse(versionInfo.downloadUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '立即更新',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
