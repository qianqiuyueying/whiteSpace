import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/image_service.dart';
import '../data/models/diary_entry.dart';
import 'diary_provider.dart';
import '../../../shared/widgets/diary_card.dart';

/// 日记详情页面
/// 
/// 设计理念：沉浸式阅读体验，优雅的内容展示
class DiaryDetailPage extends ConsumerStatefulWidget {
  final int diaryId;

  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  ConsumerState<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends ConsumerState<DiaryDetailPage> {
  DiaryEntry? _diary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    final db = await ref.read(databaseServiceProvider.future);
    final diary = await db.getDiaryById(widget.diaryId);

    if (mounted) {
      setState(() {
        _diary = diary;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDiary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除日记'),
        content: const Text('确定要删除这篇日记吗？删除后可在回收站找回。'),
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
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final diaryService = ref.read(diaryServiceProvider);
      await diaryService.deleteDiary(widget.diaryId);
      ref.read(diaryListProvider.notifier).refresh();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_diary == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
          body: Center(
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
                  '日记不存在',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mood = Mood.values[_diary!.moodIndex];
    final weather = _diary!.weatherIndex != null
        ? Weather.values[_diary!.weatherIndex!]
        : null;

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
                  _buildAppBar(context, isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 日期和心情
                          _buildHeader(mood, weather, isDark),

                          const SizedBox(height: 28),

                          // 标题
                          if (_diary!.title != null && _diary!.title!.isNotEmpty) ...[
                            Text(
                              _diary!.title!,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                letterSpacing: -0.5,
                                height: 1.3,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                            const SizedBox(height: 20),
                          ],

                          // 标签
                          if (_diary!.tags.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _diary!.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppTheme.darkCard
                                        : AppTheme.lightCard,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                                    border: Border.all(
                                      color: isDark
                                          ? AppTheme.darkBorder
                                          : AppTheme.lightBorder,
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 24),
                          ],

                          // 内容
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            child: MarkdownBody(
                              data: _diary!.content,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                  letterSpacing: 0.1,
                                ),
                                h1: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                ),
                                h2: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                                ),
                                blockquote: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                                listBullet: TextStyle(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                          // 图片
                          if (_diary!.images.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildImageSection(isDark),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration(bool isDark) {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                  .withValues(alpha: isDark ? 0.08 : 0.05),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.push('/diary/${widget.diaryId}/edit'),
            icon: Icon(
              Icons.edit_outlined,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          IconButton(
            onPressed: _deleteDiary,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Mood mood, Weather? weather, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // 心情
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // 日期和天气
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(_diary!.createdAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(_diary!.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (weather != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(weather.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        weather.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildImageSection(bool isDark) {
    final imageService = ref.read(imageServiceProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '图片',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _diary!.images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final imageUuid = _diary!.images[index];
              final imagePath = imageService.getImagePath(imageUuid);
              
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  image: DecorationImage(
                    image: FileImage(File(imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  String _formatTime(DateTime date) {
    final weekday = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${weekday[date.weekday - 1]} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}