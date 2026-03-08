import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/diary_card.dart';
import 'diary_provider.dart';
import '../../../core/constants/app_constants.dart';

/// 首页 - 日记列表
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final diaryState = ref.watch(diaryListProvider);

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
              // 顶部栏
              _buildHeader(context, isDark),
              
              // 日记列表
              Expanded(
                child: _buildDiaryList(diaryState, isDark),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '留白日记',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.push('/calendar'),
                    icon: Icon(
                      Icons.calendar_today_rounded,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/tags'),
                    icon: Icon(
                      Icons.label_outline_rounded,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/stats'),
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _searchController.clear();
                          ref.read(diaryListProvider.notifier).searchDiaries('');
                        }
                      });
                    },
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search_rounded,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/settings'),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 搜索框
          if (_isSearching) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(diaryListProvider.notifier).searchDiaries(value);
                },
                decoration: InputDecoration(
                  hintText: '搜索日记...',
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(begin: -0.2, end: 0),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDiaryList(DiaryListState diaryState, bool isDark) {
    if (diaryState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (diaryState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(diaryListProvider.notifier).refresh(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (diaryState.diaries.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(diaryListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: diaryState.diaries.length,
        itemBuilder: (context, index) {
          final diary = diaryState.diaries[index];
          return DiaryCard(
            title: diary.title,
            content: diary.content,
            createdAt: diary.createdAt,
            moodIndex: diary.moodIndex,
            tags: diary.tags,
            onTap: () => context.push('/diary/${diary.id}'),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: index * 50))
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 60,
              color: AppTheme.primaryColor.withOpacity(0.5),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.05, 1.05),
                end: const Offset(1, 1),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          
          const SizedBox(height: 24),
          
          Text(
            '开始记录你的故事',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms),
          
          const SizedBox(height: 8),
          
          Text(
            '点击下方按钮写下第一篇日记',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.push('/diary/new'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add_rounded,
          size: 32,
          color: Colors.white,
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) {
      return '夜深了，注意休息';
    } else if (hour < 12) {
      return '早上好，新的一天开始了';
    } else if (hour < 14) {
      return '中午好，记得休息';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }
}