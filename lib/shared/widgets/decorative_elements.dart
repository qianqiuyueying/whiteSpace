import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'diary_card.dart' show Mood;

/// ═══════════════════════════════════════════════════════════════════════════
/// 纸墨流年 - 装饰性组件库
///
/// 设计理念：东方美学与现代极简的融合
/// ═══════════════════════════════════════════════════════════════════════════

/// 水墨渐变背景
class InkGradientBackground extends StatelessWidget {
  final bool isDark;
  final Widget? child;

  const InkGradientBackground({
    super.key,
    required this.isDark,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A1A1F),
                  const Color(0xFF1E1E24),
                  const Color(0xFF1A1A1F),
                ]
              : [
                  const Color(0xFFFAF7F2),
                  const Color(0xFFF8F4EC),
                  const Color(0xFFFAF7F2),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// 水墨晕染效果
class InkBlotDecoration extends StatelessWidget {
  final bool isDark;
  final double opacity;
  final Alignment alignment;

  const InkBlotDecoration({
    super.key,
    required this.isDark,
    this.opacity = 0.08,
    this.alignment = Alignment.topRight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: alignment == Alignment.topRight || alignment == Alignment.topLeft ? -50 : null,
      bottom: alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft ? -50 : null,
      right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? -80 : null,
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? -80 : null,
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                  .withValues(alpha: opacity),
              (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                  .withValues(alpha: opacity * 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// 印章装饰
class SealStamp extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final bool isDark;

  const SealStamp({
    super.key,
    this.text = '留白',
    this.size = 48,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final stampColor = color ?? (isDark ? AppTheme.accentLight : AppTheme.accentColor);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(
          color: stampColor.withValues(alpha: 0.8),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: stampColor,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

/// 装饰性印章 - 用于卡片角落
class CornerSeal extends StatelessWidget {
  final bool isDark;
  final bool showText;

  const CornerSeal({
    super.key,
    required this.isDark,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Opacity(
        opacity: 0.15,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppTheme.accentLight : AppTheme.accentColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: showText
              ? Center(
                  child: Text(
                    '记',
                    style: TextStyle(
                      color: isDark ? AppTheme.accentLight : AppTheme.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// 时间轴指示器
class TimelineIndicator extends StatelessWidget {
  final DateTime date;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const TimelineIndicator({
    super.key,
    required this.date,
    this.isFirst = false,
    this.isLast = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 上方线条
        Container(
          width: 2,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ],
            ),
          ),
        ),

        // 日期节点
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
              ),
              Text(
                _getMonthName(date.month),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),

        // 下方线条
        if (!isLast)
          Expanded(
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['一月', '二月', '三月', '四月', '五月', '六月', 
                   '七月', '八月', '九月', '十月', '十一月', '十二月'];
    return months[month - 1];
  }
}

/// 装饰性分割线
class DecorativeDivider extends StatelessWidget {
  final bool isDark;
  final double width;

  const DecorativeDivider({
    super.key,
    required this.isDark,
    this.width = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDot(isDark, 3),
        const SizedBox(width: 8),
        _buildDot(isDark, 5),
        const SizedBox(width: 8),
        Container(
          width: width,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildDot(isDark, 5),
        const SizedBox(width: 8),
        _buildDot(isDark, 3),
      ],
    );
  }

  Widget _buildDot(bool isDark, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      ),
    );
  }
}

/// 纸张纹理效果
class PaperTexture extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const PaperTexture({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        child: Stack(
          children: [
            // 微妙的纸张纹理
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperTexturePainter(isDark: isDark),
              ),
            ),
            // 内容
            child,
          ],
        ),
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  final bool isDark;

  _PaperTexturePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // 固定种子以保持一致性
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.015)
      ..strokeWidth = 0.5;

    // 绘制微妙的纹理线条
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = random.nextDouble() * 20 + 5;
      final angle = random.nextDouble() * pi * 2;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + cos(angle) * length, y + sin(angle) * length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 心情环形选择器 - 简化版本
class MoodRingSelector extends StatelessWidget {
  final int selectedMood;
  final Function(int) onMoodSelected;
  final bool isDark;

  const MoodRingSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // 简化实现：使用 Wrap 代替复杂的 Stack 定位
    return SizedBox(
      width: 100,
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 中心显示当前心情
          Text(
            Mood.values[selectedMood].emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          // 心情选择行
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: List.generate(Mood.values.length, (index) {
              final mood = Mood.values[index];
              final isSelected = selectedMood == index;

              return GestureDetector(
                onTap: () => onMoodSelected(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            .withValues(alpha: 0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                          : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      mood.emoji,
                      style: TextStyle(
                        fontSize: isSelected ? 16 : 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// 浮动工具栏
class FloatingToolbar extends StatelessWidget {
  final List<ToolbarAction> actions;
  final bool isDark;

  const FloatingToolbar({
    super.key,
    required this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) {
          return _ToolbarActionButton(
            action: action,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

class ToolbarAction {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;

  const ToolbarAction({
    required this.icon,
    this.label,
    required this.onTap,
    this.isActive = false,
  });
}

class _ToolbarActionButton extends StatelessWidget {
  final ToolbarAction action;
  final bool isDark;

  const _ToolbarActionButton({
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: action.isActive
                ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            action.icon,
            size: 20,
            color: action.isActive
                ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

/// 脉冲浮动按钮
class PulsingFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const PulsingFAB({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 脉冲效果
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      .withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.3, 1.3),
                duration: 1500.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(duration: 1500.ms),

          // 主按钮
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
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
}

/// 水墨涟漪效果
class InkRippleDecoration extends StatelessWidget {
  final bool isDark;

  const InkRippleDecoration({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _InkRipplePainter(isDark: isDark),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(0.8, 0.8),
          duration: 2000.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _InkRipplePainter extends CustomPainter {
  final bool isDark;

  _InkRipplePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
          .withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, i * 15.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 装饰性角落 - 简化版本，避免布局约束问题
class DecorativeCorner extends StatelessWidget {
  final bool isDark;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  const DecorativeCorner({
    super.key,
    required this.isDark,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    // 简化实现：直接返回空组件，装饰性角落暂时禁用
    // 避免复杂的 Stack 嵌套导致的布局问题
    return const SizedBox.shrink();
  }
}

/// 心情枚举 - 导出自 diary_card.dart
// 注意: Mood 和 Weather 枚举定义在 diary_card.dart 中