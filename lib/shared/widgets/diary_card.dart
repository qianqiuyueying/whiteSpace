import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 精美的日记卡片组件
class DiaryCard extends StatelessWidget {
  final String? title;
  final String content;
  final DateTime createdAt;
  final int moodIndex;
  final List<String> tags;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DiaryCard({
    super.key,
    this.title,
    required this.content,
    required this.createdAt,
    this.moodIndex = 7,
    this.tags = const [],
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mood = Mood.values[moodIndex];
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: _getGradientForMood(moodIndex),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部：日期和心情
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tags.first,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 标题
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // 内容预览
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // 底部时间
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradientForMood(int index) {
    final gradients = [
      AppTheme.warmGradient,   // happy
      AppTheme.coolGradient,   // calm
      AppTheme.sunsetGradient, // sad
      const LinearGradient(
        colors: [Color(0xFF434343), Color(0xFF000000)],
      ),                        // angry
      AppTheme.natureGradient,  // anxious
      AppTheme.warmGradient,    // excited
      AppTheme.primaryGradient, // tired
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
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 心情枚举 (需要与 constants 中保持一致)
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