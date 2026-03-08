import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 精美的日记卡片组件
/// 
/// 设计理念：优雅的卡片设计，柔和的色彩过渡，清晰的信息层次
class DiaryCard extends StatelessWidget {
  final String? title;
  final String content;
  final DateTime createdAt;
  final int moodIndex;
  final List<String> tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? highlightText;

  const DiaryCard({
    super.key,
    this.title,
    required this.content,
    required this.createdAt,
    this.moodIndex = 7,
    this.tags = const [],
    this.onTap,
    this.onLongPress,
    this.highlightText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mood = Mood.values[moodIndex];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          child: Stack(
            children: [
              // 左侧心情指示条
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: _getGradientForMood(moodIndex),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusLG),
                      bottomLeft: Radius.circular(AppTheme.radiusLG),
                    ),
                  ),
                ),
              ),
              
              // 内容
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部：日期和心情
                    Row(
                      children: [
                        // 日期
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                                .withValues(alpha: isDark ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                          ),
                          child: Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // 时间
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            color: isDark 
                                ? AppTheme.darkTextTertiary 
                                : AppTheme.lightTextTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // 心情
                        Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ],
                    ),

                    // 标题
                    if (title != null && title!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildHighlightedText(
                        title!,
                        TextStyle(
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                        2,
                      ),
                    ],

                    // 内容预览
                    const SizedBox(height: 10),
                    _buildHighlightedText(
                      content,
                      TextStyle(
                        color: isDark 
                            ? AppTheme.darkTextSecondary 
                            : AppTheme.lightTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                      3,
                    ),

                    // 标签
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? AppTheme.darkBackgroundSecondary
                                  : AppTheme.lightBackgroundSecondary,
                              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                color: isDark 
                                    ? AppTheme.darkTextSecondary 
                                    : AppTheme.lightTextSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建高亮文本
  Widget _buildHighlightedText(String text, TextStyle style, int maxLines) {
    if (highlightText == null || highlightText!.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlightText!.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    var index = lowerText.indexOf(lowerHighlight);
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + highlightText!.length),
        style: style.copyWith(
          backgroundColor: const Color(0xFFFFE066).withValues(alpha: 0.5),
          color: const Color(0xFF1A1A1A),
          fontWeight: FontWeight.w600,
        ),
      ));

      start = index + highlightText!.length;
      index = lowerText.indexOf(lowerHighlight, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  LinearGradient _getGradientForMood(int index) {
    final gradients = [
      AppTheme.warmGradient,   // happy
      AppTheme.calmGradient,   // calm
      const LinearGradient(colors: [Color(0xFF6B8CAE), Color(0xFF8BA8C7)]), // sad
      const LinearGradient(colors: [Color(0xFFC75B5B), Color(0xFFE07A5F)]), // angry
      const LinearGradient(colors: [Color(0xFF8B7355), Color(0xFFA69076)]), // anxious
      AppTheme.warmGradient,   // excited
      const LinearGradient(colors: [Color(0xFF5C7BA8), Color(0xFF7A96BF)]), // tired
      AppTheme.primaryGradient, // neutral
    ];
    return gradients[index.clamp(0, gradients.length - 1)];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return '今天';
    } else if (dateDay == yesterday) {
      return '昨天';
    } else if (now.year == date.year) {
      return '${date.month}月${date.day}日';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 心情枚举
enum Mood {
  happy('开心', '😊'),
  calm('平静', '😌'),
  sad('难过', '😢'),
  angry('生气', '😠'),
  anxious('焦虑', '😰'),
  excited('兴奋', '🤩'),
  tired('疲惫', '😴'),
  neutral('一般', '😐');

  final String label;
  final String emoji;

  const Mood(this.label, this.emoji);
}

/// 天气枚举
enum Weather {
  sunny('晴', '☀️'),
  cloudy('多云', '⛅'),
  rainy('雨', '🌧️'),
  snowy('雪', '❄️'),
  windy('风', '💨'),
  foggy('雾', '🌫️');

  final String label;
  final String emoji;

  const Weather(this.label, this.emoji);
}