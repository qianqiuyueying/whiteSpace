import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/draft_service.dart';
import '../../../core/services/image_service.dart';
import '../data/models/diary_entry.dart';
import 'diary_provider.dart';

/// 日记编辑页面
class DiaryEditPage extends ConsumerStatefulWidget {
  final int? diaryId;

  const DiaryEditPage({super.key, this.diaryId});

  @override
  ConsumerState<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends ConsumerState<DiaryEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  int _selectedMood = 7; // 默认 neutral
  int? _selectedWeather;
  List<String> _tags = [];
  bool _isSaving = false;
  DiaryEntry? _existingDiary;

  // 自动保存相关
  Timer? _autoSaveTimer;
  bool _showSavedIndicator = false;

  // 临时图片列表（用于新日记）
  final List<String> _tempImages = [];

  @override
  void initState() {
    super.initState();
    _loadDiary();
    _setupAutoSave();
  }

  void _setupAutoSave() {
    // 每 5 秒自动保存草稿（静默保存）
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    if (_contentController.text.trim().isEmpty) return;

    final draftService = ref.read(draftServiceProvider);
    final draft = DraftData(
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      content: _contentController.text,
      moodIndex: _selectedMood,
      weatherIndex: _selectedWeather,
      tags: _tags,
      images: _existingDiary?.images ?? _tempImages,
      lastSavedAt: DateTime.now(),
    );

    await draftService.saveDraft(draft);

    if (mounted) {
      setState(() {
        _showSavedIndicator = true;
      });

      // 2 秒后隐藏指示器
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSavedIndicator = false);
        }
      });
    }
  }

  Future<void> _loadDiary() async {
    if (widget.diaryId == null) {
      // 检查是否有未保存的草稿
      await _loadDraft();
      return;
    }

    final db = await ref.read(databaseServiceProvider.future);
    final diary = await db.getDiaryById(widget.diaryId!);

    if (diary != null && mounted) {
      setState(() {
        _existingDiary = diary;
        _titleController.text = diary.title ?? '';
        _contentController.text = diary.content;
        _selectedMood = diary.moodIndex;
        _selectedWeather = diary.weatherIndex;
        _tags = List.from(diary.tags);
      });
    }
  }

  Future<void> _loadDraft() async {
    final draftService = ref.read(draftServiceProvider);
    final draft = await draftService.getDraft();

    if (draft != null && mounted) {
      final shouldRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('发现未保存的草稿'),
          content: Text(
            '找到上次编辑的草稿（${_formatDateTime(draft.lastSavedAt)}），是否恢复？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('放弃'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('恢复'),
            ),
          ],
        ),
      );

      if (shouldRestore == true) {
        setState(() {
          _titleController.text = draft.title ?? '';
          _contentController.text = draft.content;
          _selectedMood = draft.moodIndex;
          _selectedWeather = draft.weatherIndex;
          _tags = draft.tags;
          _tempImages.addAll(draft.images);
        });
      } else {
        // 清除草稿
        await draftService.clearDraft();
      }
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final diaryService = ref.read(diaryServiceProvider);

      if (_existingDiary != null) {
        // 更新现有日记
        _existingDiary!
          ..title = _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim()
          ..content = _contentController.text
          ..moodIndex = _selectedMood
          ..weatherIndex = _selectedWeather
          ..tags = _tags
          ..isSynced = false;

        await diaryService.updateDiary(_existingDiary!);
      } else {
        // 创建新日记
        await diaryService.createDiary(
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          content: _contentController.text,
          moodIndex: _selectedMood,
          weatherIndex: _selectedWeather,
          tags: _tags,
          images: _tempImages,
        );
      }

      // 保存成功后清除草稿
      final draftService = ref.read(draftServiceProvider);
      await draftService.clearDraft();

      // 刷新列表
      ref.read(diaryListProvider.notifier).refresh();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final imageService = ref.read(imageServiceProvider);
    final imagePaths = await imageService.pickFromGallery(maxImages: 9);

    if (imagePaths.isNotEmpty && mounted) {
      setState(() {
        if (_existingDiary != null) {
          _existingDiary!.images.addAll(imagePaths);
        } else {
          _tempImages.addAll(imagePaths);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (_existingDiary != null) {
        _existingDiary!.images.removeAt(index);
      } else {
        _tempImages.removeAt(index);
      }
    });
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMoodSelector(isDark),
                      const SizedBox(height: 24),
                      _buildWeatherSelector(isDark),
                      const SizedBox(height: 24),
                      _buildTitleField(isDark),
                      const SizedBox(height: 16),
                      _buildContentField(isDark),
                      _buildImageSection(isDark),
                      const SizedBox(height: 24),
                      _buildTagSection(isDark),
                    ],
                  ),
                ),
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
              Icons.close_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          // 保存指示器
          if (_showSavedIndicator)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '已保存',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          const Spacer(),
          // 图片按钮
          IconButton(
            onPressed: _pickImage,
            icon: Icon(
              Icons.image_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(_isSaving ? '保存中...' : '保存'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天的心情',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: Mood.values.asMap().entries.map((entry) {
            final index = entry.key;
            final mood = entry.value;
            final isSelected = _selectedMood == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedMood = index),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeatherSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '天气',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedWeather = null),
              child: AnimatedContainer(
                duration: 200.ms,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedWeather == null
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedWeather == null
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  '不记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedWeather == null
                        ? AppTheme.primaryColor
                        : isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ),
            ...Weather.values.asMap().entries.map((entry) {
              final index = entry.key;
              final weather = entry.value;
              final isSelected = _selectedWeather == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedWeather = index),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : isDark
                            ? AppTheme.darkCard
                            : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(weather.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        weather.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField(bool isDark) {
    return TextField(
      controller: _titleController,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
      ),
      decoration: InputDecoration(
        hintText: '标题（可选）',
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildContentField(bool isDark) {
    return TextField(
      controller: _contentController,
      maxLines: null,
      minLines: 10,
      style: TextStyle(
        fontSize: 16,
        height: 1.8,
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
      ),
      decoration: InputDecoration(
        hintText: '写下今天的故事...',
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    final images = _existingDiary?.images ?? _tempImages;

    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '图片',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: images.asMap().entries.map((entry) {
            final index = entry.key;
            final path = entry.value;
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTagSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  hintText: '添加标签',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  filled: true,
                  fillColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _addTag,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}