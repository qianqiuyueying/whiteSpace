import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../data/models/diary_entry.dart';
import 'diary_provider.dart';

/// 回收站页面
class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  List<DiaryEntry> _deletedDiaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedDiaries();
  }

  Future<void> _loadDeletedDiaries() async {
    final db = await ref.read(databaseServiceProvider.future);
    final diaries = await db.getAllDiaries(includeDeleted: true);
    final deleted = diaries.where((d) => d.isDeleted).toList();

    if (mounted) {
      setState(() {
        _deletedDiaries = deleted;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreDiary(int id) async {
    final db = await ref.read(databaseServiceProvider.future);
    final diary = await db.getDiaryById(id);
    if (diary != null) {
      diary.isDeleted = false;
      await db.saveDiary(diary);
      _loadDeletedDiaries();
      ref.read(diaryListProvider.notifier).refresh();
    }
  }

  Future<void> _permanentlyDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除'),
        content: const Text('确定要永久删除这篇日记吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await ref.read(databaseServiceProvider.future);
      await db.permanentlyDeleteDiary(id);
      _loadDeletedDiaries();
    }
  }

  Future<void> _emptyTrash() async {
    if (_deletedDiaries.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: Text('确定要清空回收站吗？将永久删除 ${_deletedDiaries.length} 篇日记。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await ref.read(databaseServiceProvider.future);
      for (final diary in _deletedDiaries) {
        await db.permanentlyDeleteDiary(diary.id);
      }
      _loadDeletedDiaries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              _buildAppBar(context, isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          Text(
            '回收站',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const Spacer(),
          if (_deletedDiaries.isNotEmpty)
            IconButton(
              onPressed: _emptyTrash,
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_deletedDiaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 80,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '回收站是空的',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedDiaries.length,
      itemBuilder: (context, index) {
        final diary = _deletedDiaries[index];
        return Dismissible(
          key: Key(diary.id.toString()),
          direction: DismissDirection.horizontal,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restore_rounded, color: Colors.white),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_forever_rounded, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _restoreDiary(diary.id);
              return false;
            } else {
              await _permanentlyDelete(diary.id);
              return false;
            }
          },
          child: Card(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            child: ListTile(
              title: Text(
                diary.title ?? '无标题',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
              ),
              subtitle: Text(
                '删除于 ${_formatDateTime(diary.updatedAt)}',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _restoreDiary(diary.id),
                    icon: const Icon(Icons.restore_rounded),
                    tooltip: '恢复',
                  ),
                  IconButton(
                    onPressed: () => _permanentlyDelete(diary.id),
                    icon: const Icon(Icons.delete_forever_rounded),
                    color: Colors.red,
                    tooltip: '永久删除',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}