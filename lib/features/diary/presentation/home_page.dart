import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/diary_card.dart';
import '../../../shared/widgets/decorative_elements.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../sync/presentation/sync_provider.dart';
import 'diary_provider.dart';

/// 首页 - 日记列表
///
/// 设计理念：纸墨流年 - 东方美学与现代极简的融合
/// 时间轴式布局，沉浸式阅读体验
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
  bool _hasAutoSynced = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSyncIfNeeded();
    });
  }

  Future<void> _autoSyncIfNeeded() async {
    if (_hasAutoSynced) return;
    _hasAutoSynced = true;

    final authState = ref.read(authProvider);
    if (authState.isBound) {
      await ref.read(syncServiceProvider).sync();
      ref.read(diaryListProvider.notifier).refresh();
    }
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
            // 多层背景装饰
            _buildBackgroundLayers(isDark),

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

  /// 多层背景装饰
  Widget _buildBackgroundLayers(bool isDark) {
    return Stack(
      children: [
        // 基础渐变背景
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark ? AppGradients.inkWashDark : AppGradients.inkWashLight,
            ),
          ),
        ),

        // 右上角水墨晕染
        InkBlotDecoration(
          isDark: isDark,
          opacity: isDark ? 0.06 : 0.04,
          alignment: Alignment.topRight,
        ),

        // 左下角水墨晕染
        InkBlotDecoration(
          isDark: isDark,
          opacity: isDark ? 0.04 : 0.03,
          alignment: Alignment.bottomLeft,
        ),

        // 装饰性印章
        Positioned(
          bottom: 100,
          right: -20,
          child: Opacity(
            opacity: 0.06,
            child: SealStamp(
              text: '留白',
              size: 120,
              isDark: isDark,
            ),
          ),
        ).animate().fadeIn(delay: 800.ms, duration: 1000.ms),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isScrolled
            ? (isDark ? AppTheme.darkBackground : AppTheme.lightBackground)
                .withValues(alpha: 0.95)
            : Colors.transparent,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : InkColors.lightInk.withValues(alpha: 0.3),
                  blurRadius: 20,
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
                      // 主标题 - 带装饰
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 装饰性印章
                          Container(
                            width: 6,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: AppGradients.sealGradient,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ).animate().scaleY(
                            begin: 0,
                            end: 1,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '留白',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.darkText : AppTheme.lightText,
                              letterSpacing: 2,
                              height: 1.1,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // 问候语
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
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
                  boxShadow: AppShadows.inkShadow(isDark),
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
            // 水墨涟漪加载动画
            InkRippleDecoration(isDark: isDark),
            const SizedBox(height: 24),
            Text(
              '加载中...',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    if (diaryState.error != null) {
      return _buildErrorState(isDark);
    }

    if (diaryState.diaries.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // 按日期分组日记
    final groupedDiaries = _groupDiariesByDate(diaryState.diaries);
    final dates = groupedDiaries.keys.toList();

    return RefreshIndicator(
      color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      onRefresh: () => ref.read(diaryListProvider.notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 日记列表
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, dateIndex) {
                  final date = dates[dateIndex];
                  final diaries = groupedDiaries[date]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期分隔标题
                      if (dateIndex > 0 || diaryState.searchQuery.isEmpty) ...[
                        _buildDateSectionHeader(date, isDark, dateIndex),
                        const SizedBox(height: 16),
                      ],
                      
                      // 该日期的日记卡片
                      ...diaries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final diary = entry.value;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildEnhancedDiaryCard(
                            diary: diary,
                            isDark: isDark,
                            index: dateIndex * 10 + index,
                            searchQuery: diaryState.searchQuery,
                          ),
                        );
                      }),
                    ],
                  );
                },
                childCount: dates.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日期分组标题
  Widget _buildDateSectionHeader(DateTime date, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          // 装饰性日期标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      .withValues(alpha: isDark ? 0.15 : 0.1),
                  (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      .withValues(alpha: isDark ? 0.08 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_note_rounded,
                  size: 16,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatSectionDate(date),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          // 装饰线
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: -0.1, end: 0);
  }

  /// 增强版日记卡片
  Widget _buildEnhancedDiaryCard({
    required diary,
    required bool isDark,
    required int index,
    String? searchQuery,
  }) {
    // 简化实现：直接返回 DiaryCard，移除 Stack 结构
    return DiaryCard(
      title: diary.title,
      content: diary.content,
      createdAt: diary.createdAt,
      moodIndex: diary.moodIndex,
      tags: diary.tags,
      highlightText: searchQuery?.isNotEmpty == true ? searchQuery : null,
      onTap: () => context.push('/diary/${diary.id}'),
    )
    .animate()
    .fadeIn(
      delay: Duration(milliseconds: index * 30),
      duration: 400.ms,
    )
    .slideY(
      begin: 0.08,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    )
    .shimmer(
      duration: 1200.ms,
      color: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.white.withValues(alpha: 0.5),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SealColors.vermilion.withValues(alpha: 0.1),
                    SealColors.cinnabar.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: SealColors.vermilion,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                letterSpacing: 1,
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
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: () => ref.read(diaryListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('重新加载'),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  side: BorderSide(
                    color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            // 装饰性水墨画效果
            Stack(
              alignment: Alignment.center,
              children: [
                // 外圈涟漪
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                          .withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 3000.ms,
                      curve: Curves.easeInOut,
                    )
                    .fadeIn(duration: 1500.ms)
                    .then()
                    .scale(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1, 1),
                      duration: 3000.ms,
                      curve: Curves.easeInOut,
                    ),

                // 中圈
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            .withValues(alpha: isDark ? 0.12 : 0.08),
                        (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            .withValues(alpha: isDark ? 0.06 : 0.03),
                      ],
                    ),
                  ),
                ),

                // 中心图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCard
                        : AppTheme.lightCard,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.inkShadow(isDark),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 36,
                    color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 标题
            Text(
              '开始记录你的故事',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                letterSpacing: 1,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            // 副标题
            Text(
              '每一篇日记，都是时光的礼物',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                height: 1.6,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 8),

            // 装饰性分割线
            DecorativeDivider(isDark: isDark, width: 60)
                .animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 36),

            // 开始写作按钮
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: AppShadows.glowShadow(
                  isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                  opacity: 0.3,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/diary/new'),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '写第一篇日记',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return PulsingFAB(
      icon: Icons.edit_rounded,
      label: '写日记',
      onTap: () => context.push('/diary/new'),
      isDark: isDark,
    );
  }

  /// 按日期分组日记
  Map<DateTime, List> _groupDiariesByDate(List diaries) {
    final grouped = <DateTime, List>{};
    
    for (final diary in diaries) {
      final date = DateTime(
        diary.createdAt.year,
        diary.createdAt.month,
        diary.createdAt.day,
      );
      
      grouped.putIfAbsent(date, () => []).add(diary);
    }
    
    return grouped;
  }

  String _formatSectionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return '今天';
    } else if (date == yesterday) {
      return '昨天';
    } else if (now.year == date.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
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