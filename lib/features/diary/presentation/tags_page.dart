import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../data/models/diary_entry.dart';
import '../../../core/constants/app_constants.dart';

/// 标签筛选页面
class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({super.key});

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends ConsumerState<TagsPage> {
  Map<String, int> _tagCounts = {};
  bool _isLoading = true;
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final db = await ref.read(databaseServiceProvider.future);
    final diaries = await db.getAllDiaries();

    final tagCounts = <String, int>{};
    for (final diary in diaries) {
      for (final tag in diary.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    if (mounted) {
      setState(() {
        _tagCounts = tagCounts;
        _isLoading = false;
      });
    }
  }

  Future<void> _renameTag(String oldName, String newName) async {
    if (newName.trim().isEmpty || newName == oldName) return;

    final db = await ref.read(databaseServiceProvider.future);
    final diaries = await db.getDiariesByTag(oldName);

    for (final diary in diaries) {
      diary.tags.remove(oldName);
      if (!diary.tags.contains(newName)) {
        diary.tags.add(newName);
      }
      await db.saveDiary(diary);
    }

    _loadTags();
  }

  Future<void> _deleteTag(String tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除标签'),
        content: Text('确定要删除标签 "$tag" 吗？该标签将从所有日记中移除。'),
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
      final diaries = await db.getDiariesByTag(tag);

      for (final diary in diaries) {
        diary.tags.remove(tag);
        await db.saveDiary(diary);
      }

      _loadTags();
    }
  }

  void _showRenameDialog(String tag) {
    final controller = TextEditingController(text: tag);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名标签'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新标签名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _renameTag(tag, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
            '标签',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_tagCounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline_rounded,
              size: 80,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有标签',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在日记中添加标签后会显示在这里',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final sortedTags = _tagCounts.keys.toList()
      ..sort((a, b) => _tagCounts[b]!.compareTo(_tagCounts[a]!));

    return Column(
      children: [
        // 标签云
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sortedTags.map((tag) {
              final count = _tagCounts[tag]!;
              final isSelected = _selectedTag == tag;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTag = isSelected ? null : tag;
                  });
                },
                onLongPress: () => _showTagOptions(tag),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.label_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppTheme.darkText : AppTheme.lightText),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 选中标签的日记列表
        if (_selectedTag != null) Expanded(child: _buildDiaryList(_selectedTag!, isDark)),
      ],
    );
  }

  Widget _buildDiaryList(String tag, bool isDark) {
    return FutureBuilder<List<DiaryEntry>>(
      future: _getDiariesByTag(tag),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final diaries = snapshot.data ?? [];

        if (diaries.isEmpty) {
          return Center(
            child: Text(
              '没有相关日记',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: diaries.length,
          itemBuilder: (context, index) {
            final diary = diaries[index];
            return Card(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  Mood.values[diary.moodIndex].emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  diary.title ?? '无标题',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                subtitle: Text(
                  diary.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/diary/${diary.id}'),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<DiaryEntry>> _getDiariesByTag(String tag) async {
    final db = await ref.read(databaseServiceProvider.future);
    return db.getDiariesByTag(tag);
  }

  void _showTagOptions(String tag) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('重命名'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(tag);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteTag(tag);
              },
            ),
          ],
        ),
      ),
    );
  }
}