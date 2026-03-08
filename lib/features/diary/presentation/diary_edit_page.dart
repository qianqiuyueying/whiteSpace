import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/draft_service.dart';
import '../../../core/services/image_service.dart';
import '../data/models/diary_entry.dart';
import 'diary_provider.dart';
import '../../../shared/widgets/diary_card.dart';

/// 日记编辑页面
/// 
/// 设计理念：沉浸式写作体验，简洁优雅的界面
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

  int _selectedMood = 7;
  int? _selectedWeather;
  List<String> _tags = [];
  bool _isSaving = false;
  DiaryEntry? _existingDiary;

  Timer? _autoSaveTimer;
  bool _showSavedIndicator = false;
  final List<String> _tempImages = [];

  @override
  void initState() {
    super.initState();
    _loadDiary();
    _setupAutoSave();
  }

  void _setupAutoSave() {
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
      setState(() => _showSavedIndicator = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSavedIndicator = false);
      });
    }
  }

  Future<void> _loadDiary() async {
    if (widget.diaryId == null) {
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
          content: Text('找到上次编辑的草稿，是否恢复？'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
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
        await draftService.clearDraft();
      }
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
        SnackBar(
          content: const Text('请输入日记内容'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final diaryService = ref.read(diaryServiceProvider);

      if (_existingDiary != null) {
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

      final draftService = ref.read(draftServiceProvider);
      await draftService.clearDraft();

      ref.read(diaryListProvider.notifier).refresh();

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    setState(() => _tags.remove(tag));
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildMoodSelector(isDark),
                      const SizedBox(height: 20),
                      _buildWeatherSelector(isDark),
                      const SizedBox(height: 28),
                      _buildTitleField(isDark),
                      const SizedBox(height: 16),
                      _buildContentField(isDark),
                      _buildImageSection(isDark),
                      const SizedBox(height: 24),
                      _buildTagSection(isDark),
                      const SizedBox(height: 40),
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
    return Container(
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
          if (_showSavedIndicator)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 14,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '已保存',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
          const Spacer(),
          IconButton(
            onPressed: _pickImage,
            icon: Icon(
              Icons.image_outlined,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              style: TextButton.styleFrom(
                foregroundColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
              ),
              child: _isSaving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '保存',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Mood.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final mood = Mood.values[index];
              final isSelected = _selectedMood == index;

              return GestureDetector(
                onTap: () => setState(() => _selectedMood = index),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            .withValues(alpha: isDark ? 0.2 : 0.12)
                        : isDark
                            ? AppTheme.darkCard
                            : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                          : isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              : isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: Weather.values.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedWeather == null;
                return GestureDetector(
                  onTap: () => setState(() => _selectedWeather = null),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              .withValues(alpha: isDark ? 0.2 : 0.12)
                          : isDark
                              ? AppTheme.darkCard
                              : AppTheme.lightCard,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            : isDark
                                ? AppTheme.darkBorder
                                : AppTheme.lightBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '不记录',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            : isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                );
              }

              final weather = Weather.values[index - 1];
              final isSelected = _selectedWeather == index - 1;

              return GestureDetector(
                onTap: () => setState(() => _selectedWeather = index - 1),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            .withValues(alpha: isDark ? 0.2 : 0.12)
                        : isDark
                            ? AppTheme.darkCard
                            : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                          : isDark
                              ? AppTheme.darkBorder
                              : AppTheme.lightBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(weather.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        weather.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              : isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField(bool isDark) {
    return TextField(
      controller: _titleController,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
        letterSpacing: -0.5,
        height: 1.3,
      ),
      decoration: InputDecoration(
        hintText: '标题',
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextTertiary
              : AppTheme.lightTextTertiary,
          fontWeight: FontWeight.w400,
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
      minLines: 8,
      style: TextStyle(
        fontSize: 16,
        height: 1.8,
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
        letterSpacing: 0.1,
      ),
      decoration: InputDecoration(
        hintText: '写下今天的故事...',
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextTertiary
              : AppTheme.lightTextTertiary,
          height: 1.8,
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
        const SizedBox(height: 20),
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
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      image: DecorationImage(
                        image: FileImage(File(images[index])),
                        fit: BoxFit.cover,
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
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
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
            },
          ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark
                            ? AppTheme.darkTextTertiary
                            : AppTheme.lightTextTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: '添加标签',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextTertiary
                          : AppTheme.lightTextTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              IconButton(
                onPressed: _addTag,
                icon: Icon(
                  Icons.add_rounded,
                  color: isDark
                      ? AppTheme.primaryLight
                      : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}