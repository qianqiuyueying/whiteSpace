import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/diary_card.dart';
import 'diary_provider.dart';

/// 首页 - 日记列表
/// 
/// 设计理念：温暖的纸张质感，优雅的排版，沉浸式阅读体验
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isScrolled = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 20;
    if (isScrolled != _isScrolled) {
      setState(() => _isScrolled = isScrolled);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diaryState = ref.watch(diaryListProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: Stack(
          children: [
            // 背景装饰
            _buildBackgroundDecoration(isDark),
            
            // 主内容
            SafeArea(
              child: Column(
                children: [
                  // 顶部栏
                  _buildHeader(context, isDark),
                  
                  // 日记列表
                  Expanded(
                    child: _buildDiaryList(diaryState, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFAB(context, isDark),
      ),
    );
  }

  /// 背景装饰
  Widget _buildBackgroundDecoration(bool isDark) {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                  .withValues(alpha: isDark ? 0.08 : 0.06),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isScrolled 
            ? (isDark ? AppTheme.darkBackground : AppTheme.lightBackground)
            : Colors.transparent,
        boxShadow: _isScrolled 
            ? [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '留白',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark 
                              ? AppTheme.darkTextSecondary 
                              : AppTheme.lightTextSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 右侧操作按钮
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderButton(
                      icon: Icons.calendar_month_rounded,
                      onTap: () => context.push('/calendar'),
                      isDark: isDark,
                    ),
                    _buildHeaderButton(
                      icon: Icons.local_offer_outlined,
                      onTap: () => context.push('/tags'),
                      isDark: isDark,
                    ),
                    _buildHeaderButton(
                      icon: Icons.insights_rounded,
                      onTap: () => context.push('/stats'),
                      isDark: isDark,
                    ),
                    _buildHeaderButton(
                      icon: _isSearching ? Icons.close : Icons.search_rounded,
                      onTap: () {
                        setState(() {
                          _isSearching = !_isSearching;
                          if (!_isSearching) {
                            _searchController.clear();
                            ref.read(diaryListProvider.notifier).searchDiaries('');
                          }
                        });
                      },
                      isDark: isDark,
                    ),
                    _buildHeaderButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/settings'),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 搜索框
          if (_isSearching) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    width: 1,
                  ),
                  boxShadow: AppTheme.cardShadow(isDark),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(diaryListProvider.notifier).searchDiaries(value);
                  },
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: '搜索日记内容...',
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark 
                          ? AppTheme.darkTextTertiary 
                          : AppTheme.lightTextTertiary,
                      size: 22,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildDiaryList(DiaryListState diaryState, bool isDark) {
    if (diaryState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (diaryState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请检查网络连接后重试',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark 
                      ? AppTheme.darkTextSecondary 
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => ref.read(diaryListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    if (diaryState.diaries.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      onRefresh: () => ref.read(diaryListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        itemCount: diaryState.diaries.length,
        itemBuilder: (context, index) {
          final diary = diaryState.diaries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DiaryCard(
              title: diary.title,
              content: diary.content,
              createdAt: diary.createdAt,
              moodIndex: diary.moodIndex,
              tags: diary.tags,
              highlightText: diaryState.searchQuery.isNotEmpty 
                  ? diaryState.searchQuery 
                  : null,
              onTap: () => context.push('/diary/${diary.id}'),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: index * 30),
            duration: 300.ms,
          ).slideY(
            begin: 0.05,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 装饰图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                        .withValues(alpha: 0.15),
                    (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                        .withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 48,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.03, 1.03),
                  duration: 2500.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scale(
                  begin: const Offset(1.03, 1.03),
                  end: const Offset(1, 1),
                  duration: 2500.ms,
                  curve: Curves.easeInOut,
                ),

            const SizedBox(height: 32),

            Text(
              '开始记录你的故事',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                letterSpacing: -0.3,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            Text(
              '每一篇日记，都是时光的礼物',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark 
                    ? AppTheme.darkTextSecondary 
                    : AppTheme.lightTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            // 开始写作按钮
            TextButton.icon(
              onPressed: () => context.push('/diary/new'),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('写第一篇日记'),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  side: BorderSide(
                    color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        boxShadow: AppTheme.fabShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/diary/new'),
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Text(
                  '写日记',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 300.ms);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了，记得休息';
    } else if (hour < 9) {
      return '早安，新的一天';
    } else if (hour < 12) {
      return '上午好';
    } else if (hour < 14) {
      return '午安';
    } else if (hour < 18) {
      return '下午好';
    } else if (hour < 22) {
      return '晚上好';
    } else {
      return '夜深了，记得休息';
    }
  }
}