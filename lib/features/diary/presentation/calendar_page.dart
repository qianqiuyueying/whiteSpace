import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../data/models/diary_entry.dart';
import '../../../shared/widgets/diary_card.dart';

/// 日历视图页面
/// 
/// 设计理念：优雅的日历视图，清晰展示日记分布
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<String, List<DiaryEntry>> _diariesByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadDiaries();
  }

  /// 将 DateTime 转换为字符串 key（确保日期匹配正确）
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDiaries() async {
    final db = await ref.read(databaseServiceProvider.future);
    final diaries = await db.getAllDiaries();

    final diariesByDate = <String, List<DiaryEntry>>{};
    for (final diary in diaries) {
      final key = _dateKey(diary.createdAt);
      if (!diariesByDate.containsKey(key)) {
        diariesByDate[key] = [];
      }
      diariesByDate[key]!.add(diary);
    }

    if (mounted) {
      setState(() {
        _diariesByDate = diariesByDate;
        _isLoading = false;
      });
    }
  }

  List<DiaryEntry> _getDiariesForDay(DateTime day) {
    return _diariesByDate[_dateKey(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: _buildCalendar(isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          Text(
            '日历',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    final selectedDiaries = _getDiariesForDay(_selectedDay);

    return Column(
      children: [
        // 日历组件
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: TableCalendar<DiaryEntry>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getDiariesForDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: '月',
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
              selectedDecoration: BoxDecoration(
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: isDark ? AppTheme.accentLight : AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: TextStyle(
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),

        const SizedBox(height: 16),

        // 选中日期的日记列表
        Expanded(
          child: selectedDiaries.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: selectedDiaries.length,
                  itemBuilder: (context, index) {
                    final diary = selectedDiaries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DiaryCard(
                        title: diary.title,
                        content: diary.content,
                        createdAt: diary.createdAt,
                        moodIndex: diary.moodIndex,
                        tags: diary.tags,
                        onTap: () => context.push('/diary/${diary.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 36,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '这天还没有日记',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮记录这一天',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.push('/diary/new'),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('写日记'),
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}