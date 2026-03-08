import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'auth_provider.dart';

/// 登录页面
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

    return Scaffold(
      body: Container(
        width: double.infinity,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo 和标题
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.5, 0.5),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            )
                            .fadeIn(duration: 400.ms),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          '留白日记',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          '记录生活，留下美好',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Token 输入
                  BeautifulTextField(
                    controller: _tokenController,
                    labelText: 'GitHub Personal Access Token',
                    hintText: '输入您的 GitHub Token',
                    obscureText: _obscureToken,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureToken = !_obscureToken;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入 GitHub Token';
                      }
                      if (value.length < 40) {
                        return 'Token 格式不正确';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 400.ms)
                      .slideX(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // 帮助链接
                  TextButton.icon(
                    onPressed: _openGithubTokenPage,
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('如何获取 Token？'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 400.ms),
                  
                  const SizedBox(height: 32),
                  
                  // 登录按钮
                  BeautifulButton(
                    text: '登录',
                    isLoading: authState.isLoading,
                    onPressed: _login,
                  )
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                  
                  if (authState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // 说明文字
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '为什么需要 Token？',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 使用 GitHub Gist 免费存储您的日记\n'
                          '• 数据完全由您掌控，安全可靠\n'
                          '• 支持 Windows 和 Android 多端同步\n'
                          '• Token 仅用于访问您的 Gist，不会上传到任何服务器',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1200.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}