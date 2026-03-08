import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import 'auth_provider.dart';

/// 登录页面
/// 
/// 设计理念：优雅简洁的登录体验，温暖的品牌感
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureToken = true;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).loginWithToken(
      _tokenController.text.trim(),
    );

    if (success && mounted) {
      // 登录成功，导航会自动处理
    }
  }

  Future<void> _openGithubTokenPage() async {
    final uri = Uri.parse('https://github.com/settings/tokens/new?description=留白日记&scopes=gist');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            // 背景装饰
            ..._buildBackgroundDecorations(isDark),
            
            // 主内容
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: size.height * 0.12),

                      // Logo 和标题
                      _buildHeader(isDark),

                      SizedBox(height: size.height * 0.08),

                      // Token 输入
                      _buildTokenInput(isDark),

                      const SizedBox(height: 12),

                      // 帮助链接
                      _buildHelpLink(isDark),

                      const SizedBox(height: 28),

                      // 登录按钮
                      _buildLoginButton(authState, isDark),

                      // 错误提示
                      if (authState.error != null) ...[
                        const SizedBox(height: 20),
                        _buildErrorTip(authState.error!, isDark),
                      ],

                      SizedBox(height: size.height * 0.06),

                      // 说明卡片
                      _buildInfoCard(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundDecorations(bool isDark) {
    return [
      // 右上角光晕
      Positioned(
        top: -80,
        right: -80,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      
      // 左下角光晕
      Positioned(
        bottom: -100,
        left: -100,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppTheme.accentColor.withValues(alpha: isDark ? 0.08 : 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Logo
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            size: 44,
            color: Colors.white,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.6, 0.6),
              duration: 600.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 400.ms),

        const SizedBox(height: 28),

        // 标题
        Text(
          '留白',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            letterSpacing: -1.5,
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: 8),

        Text(
          '记录生活，留下美好',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: isDark 
                ? AppTheme.darkTextSecondary 
                : AppTheme.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildTokenInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: AppTheme.cardShadow(isDark),
      ),
      child: TextFormField(
        controller: _tokenController,
        obscureText: _obscureToken,
        style: TextStyle(
          color: isDark ? AppTheme.darkText : AppTheme.lightText,
          fontSize: 15,
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureToken
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: isDark 
                  ? AppTheme.darkTextTertiary 
                  : AppTheme.lightTextTertiary,
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _obscureToken = !_obscureToken;
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
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 400.ms)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildHelpLink(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _openGithubTokenPage,
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
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 400.ms);
  }

  Widget _buildLoginButton(AuthState authState, bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authState.isLoading ? null : _login,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Center(
            child: authState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '开始使用',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 400.ms)
        .slideY(begin: 0.15, end: 0);
  }

  Widget _buildErrorTip(String error, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppTheme.accentColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: AppTheme.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).shake(hz: 2, duration: 300.ms);
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.darkCard 
            : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                '数据安全说明',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoItem(
            '使用 GitHub Gist 免费存储日记',
            Icons.cloud_outlined,
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInfoItem(
            '数据完全由您掌控，安全可靠',
            Icons.lock_outline_rounded,
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInfoItem(
            '支持多端同步，随时随地记录',
            Icons.devices_rounded,
            isDark,
          ),
          const SizedBox(height: 10),
          _buildInfoItem(
            'Token 仅用于访问您的 Gist',
            Icons.security_rounded,
            isDark,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoItem(String text, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark 
              ? AppTheme.darkTextTertiary 
              : AppTheme.lightTextTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDark 
                  ? AppTheme.darkTextSecondary 
                  : AppTheme.lightTextSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}