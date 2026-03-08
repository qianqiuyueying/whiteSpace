# 留白日记应用改进实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将留白日记从一个技术 demo 改进为功能完善、用户体验优秀的产品级应用

**Architecture:** 基于现有 Flutter + Riverpod + Isar 架构，按优先级分阶段实现编辑器、同步、日历等核心功能改进

**Tech Stack:** Flutter, Riverpod, Isar, go_router, flutter_secure_storage, dio

---

## 优先级说明

| 优先级 | 任务 | 预计时间 |
|--------|------|----------|
| P0 | 草稿自动保存 + 图片支持 | 2-3 小时 |
| P1 | 日历视图 + 回收站 | 4-5 小时 |
| P2 | 自动同步 + 标签筛选 + 搜索高亮 | 3-4 小时 |
| P3 | 写作目标 + PDF 导出 + 小组件 | 3-4 小时 |

---

## ⚠️ 重要注意事项

### 路由配置
所有新路由统一添加到 `lib/core/router/app_router.dart`，不要修改 `lib/main.dart` 中的路由。

### 代码风格
- 遵循现有项目的代码风格
- 使用 `flutter analyze` 检查代码质量
- 每个任务完成后单独提交

---

## P0: 草稿自动保存

### Task 1: 创建草稿服务

**Files:**
- Create: `lib/core/services/draft_service.dart`

**Step 1: 创建草稿服务类**

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 草稿数据
class DraftData {
  final String? title;
  final String content;
  final int moodIndex;
  final int? weatherIndex;
  final List<String> tags;
  final List<String> images;
  final DateTime lastSavedAt;

  DraftData({
    this.title,
    required this.content,
    this.moodIndex = 7,
    this.weatherIndex,
    this.tags = const [],
    this.images = const [],
    required this.lastSavedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'moodIndex': moodIndex,
      'weatherIndex': weatherIndex,
      'tags': tags,
      'images': images,
      'lastSavedAt': lastSavedAt.toIso8601String(),
    };
  }

  factory DraftData.fromJson(Map<String, dynamic> json) {
    return DraftData(
      title: json['title'],
      content: json['content'] ?? '',
      moodIndex: json['moodIndex'] ?? 7,
      weatherIndex: json['weatherIndex'],
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      lastSavedAt: DateTime.parse(json['lastSavedAt']),
    );
  }
}

/// 草稿服务
class DraftService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _draftKey = 'current_draft';

  /// 保存草稿
  Future<void> saveDraft(DraftData draft) async {
    final json = jsonEncode(draft.toJson());
    await _storage.write(key: _draftKey, value: json);
  }

  /// 获取草稿
  Future<DraftData?> getDraft() async {
    final json = await _storage.read(key: _draftKey);
    if (json == null) return null;

    try {
      return DraftData.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  /// 清除草稿
  Future<void> clearDraft() async {
    await _storage.delete(key: _draftKey);
  }

  /// 检查是否有草稿
  Future<bool> hasDraft() async {
    final draft = await getDraft();
    return draft != null && draft.content.isNotEmpty;
  }
}

final draftServiceProvider = Provider<DraftService>((ref) {
  return DraftService();
});
```

**Step 2: Commit**

```bash
git add lib/core/services/draft_service.dart
git commit -m "feat: create draft auto-save service"
```

---

### Task 2: 在编辑页面集成自动保存

**Files:**
- Modify: `lib/features/diary/presentation/diary_edit_page.dart`

**Step 1: 添加必要的 import 和状态变量**

在文件顶部添加：
```dart
import 'dart:async';
import '../../../core/services/draft_service.dart';
```

在 `_DiaryEditPageState` 类中添加状态变量：
```dart
Timer? _autoSaveTimer;
DateTime? _lastSavedAt;
bool _showSavedIndicator = false;
```

**Step 2: 添加自动保存逻辑**

修改 `initState` 和 `dispose`：
```dart
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
    images: _existingDiary?.images ?? [],
    lastSavedAt: DateTime.now(),
  );

  await draftService.saveDraft(draft);

  if (mounted) {
    setState(() {
      _lastSavedAt = draft.lastSavedAt;
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

@override
void dispose() {
  _autoSaveTimer?.cancel();
  _titleController.dispose();
  _contentController.dispose();
  _tagController.dispose();
  super.dispose();
}
```

**Step 3: 在 AppBar 中添加保存指示器**

修改 `_buildAppBar` 方法，在 Row 的 children 中添加保存指示器：
```dart
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
```

**Step 4: 在页面加载时检查草稿**

修改 `_loadDiary` 方法：
```dart
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
```

**Step 5: 保存成功后清除草稿**

修改 `_save` 方法，在成功后添加：
```dart
// 保存成功后清除草稿
final draftService = ref.read(draftServiceProvider);
await draftService.clearDraft();
```

**Step 6: Commit**

```bash
git add lib/features/diary/presentation/diary_edit_page.dart
git commit -m "feat: add auto-save draft functionality with silent indicator"
```

---

## P0: 图片支持

### Task 3: 在编辑器中集成图片上传功能

**Files:**
- Modify: `lib/features/diary/presentation/diary_edit_page.dart`
- Read: `lib/core/services/image_service.dart` (了解现有实现)

**Step 1: 查看现有图片服务**

先读取 `lib/core/services/image_service.dart` 了解现有实现。

**Step 2: 在编辑页面添加图片选择功能**

在 `_DiaryEditPageState` 中添加：
```dart
Future<void> _pickImage() async {
  final imageService = ref.read(imageServiceProvider);
  final imagePath = await imageService.pickImage();
  
  if (imagePath != null && mounted) {
    setState(() {
      if (_existingDiary != null) {
        _existingDiary!.images.add(imagePath);
      } else {
        // 对于新日记，临时存储图片路径
        _tempImages.add(imagePath);
      }
    });
  }
}

// 添加临时图片列表
final List<String> _tempImages = [];
```

**Step 3: 在内容区域下方添加图片预览**

在 `_buildContentField` 后添加图片预览区域：
```dart
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

void _removeImage(int index) {
  setState(() {
    if (_existingDiary != null) {
      _existingDiary!.images.removeAt(index);
    } else {
      _tempImages.removeAt(index);
    }
  });
}
```

**Step 4: 在 AppBar 添加图片按钮**

在 `_buildAppBar` 的 Row 中，保存按钮前添加：
```dart
IconButton(
  onPressed: _pickImage,
  icon: Icon(
    Icons.image_rounded,
    color: isDark ? AppTheme.darkText : AppTheme.lightText,
  ),
),
```

**Step 5: 更新 _save 方法处理图片**

```dart
// 在创建新日记时包含图片
await diaryService.createDiary(
  title: _titleController.text.trim().isEmpty
      ? null
      : _titleController.text.trim(),
  content: _contentController.text,
  moodIndex: _selectedMood,
  weatherIndex: _selectedWeather,
  tags: _tags,
  images: _tempImages, // 添加图片
);
```

**Step 6: Commit**

```bash
git add lib/features/diary/presentation/diary_edit_page.dart
git commit -m "feat: add image upload support in editor"
```

---

## P1: 日历视图

### Task 4: 创建日历视图页面

**Files:**
- Create: `lib/features/diary/presentation/calendar_page.dart`
- Add dependency: `table_calendar: ^3.1.1` to `pubspec.yaml`

**Step 1: 添加依赖**

Modify `pubspec.yaml`:
```yaml
# 日历
table_calendar: ^3.1.1
```

```bash
flutter pub get
```

**Step 2: 创建日历页面**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/database_service.dart';
import '../data/models/diary_entry.dart';

/// 日历视图页面
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<DiaryEntry>> _diaries = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final db = await ref.read(databaseServiceProvider.future);
    final diaries = await db.getAllDiaries();

    final diariesByDay = <DateTime, List<DiaryEntry>>{};
    for (final diary in diaries) {
      final day = DateTime(
        diary.createdAt.year,
        diary.createdAt.month,
        diary.createdAt.day,
      );
      if (!diariesByDay.containsKey(day)) {
        diariesByDay[day] = [];
      }
      diariesByDay[day]!.add(diary);
    }

    if (mounted) {
      setState(() {
        _diaries = diariesByDay;
        _isLoading = false;
      });
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
            '日历',
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

  Widget _buildCalendar(bool isDark) {
    final selectedDiaries = _diaries[_selectedDay] ?? [];

    return Column(
      children: [
        TableCalendar<DiaryEntry>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) => _diaries[day] ?? [],
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(
              color: AppTheme.primaryColor,
            ),
            holidayTextStyle: TextStyle(
              color: AppTheme.primaryColor,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
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
            ),
            weekendStyle: TextStyle(
              color: AppTheme.primaryColor,
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
        const Divider(),
        Expanded(
          child: selectedDiaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note_outlined,
                        size: 64,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '这天还没有日记',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/diary/new'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('写一篇'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedDiaries.length,
                  itemBuilder: (context, index) {
                    final diary = selectedDiaries[index];
                    return Card(
                      child: ListTile(
                        leading: Text(
                          Mood.values[diary.moodIndex].emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          diary.title ?? '无标题',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          diary.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.push('/diary/${diary.id}'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
```

**Step 3: Commit**

```bash
git add pubspec.yaml lib/features/diary/presentation/calendar_page.dart
git commit -m "feat: add calendar view page"
```

---

### Task 5: 添加日历路由和入口

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/diary/presentation/home_page.dart`

**Step 1: 在路由中添加日历页面**

Modify `lib/core/router/app_router.dart`:
```dart
import '../../features/diary/presentation/calendar_page.dart';

// 在 routes 数组中添加：
GoRoute(
  path: '/calendar',
  builder: (context, state) => const CalendarPage(),
),
```

**Step 2: 在首页添加日历按钮**

Modify `lib/features/diary/presentation/home_page.dart`:

在 `_buildHeader` 方法的 Row 中，在统计按钮前添加：
```dart
IconButton(
  onPressed: () => context.push('/calendar'),
  icon: Icon(
    Icons.calendar_today_rounded,
    color: isDark ? AppTheme.darkText : AppTheme.lightText,
  ),
),
```

**Step 3: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/diary/presentation/home_page.dart
git commit -m "feat: add calendar entry point to home page"
```

---

## P1: 回收站功能

### Task 6: 创建回收站页面

**Files:**
- Create: `lib/features/diary/presentation/trash_page.dart`

**Step 1: 创建回收站页面**

```dart
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
              icon: Icon(
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
            child: ListTile(
              title: Text(
                diary.title ?? '无标题',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
```

**Step 2: Commit**

```bash
git add lib/features/diary/presentation/trash_page.dart
git commit -m "feat: add trash page with restore/delete functionality"
```

---

### Task 7: 添加回收站路由和入口

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

**Step 1: 添加路由**

Modify `lib/core/router/app_router.dart`:
```dart
import '../../features/diary/presentation/trash_page.dart';

// 在 routes 数组中添加：
GoRoute(
  path: '/trash',
  builder: (context, state) => const TrashPage(),
),
```

**Step 2: 在设置页面添加入口**

Modify `lib/features/settings/presentation/settings_page.dart`:

在数据管理 Section 的导出日记前添加：
```dart
_buildListTile(
  icon: Icons.delete_outline_rounded,
  title: '回收站',
  subtitle: '查看已删除的日记',
  onTap: () => context.push('/trash'),
  isDark: isDark,
),
```

**Step 3: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/settings/presentation/settings_page.dart
git commit -m "feat: add trash entry point in settings"
```

---

## P2: 自动同步

### Task 8: 改进同步服务支持自动同步

**Files:**
- Modify: `lib/features/sync/domain/sync_service.dart` (如果存在)
- Modify: `lib/features/sync/presentation/sync_provider.dart`

**Step 1: 查看现有同步服务**

先读取现有文件了解结构，然后添加：
- 自动同步触发器（日记创建/更新后）
- 同步状态监听
- 同步冲突检测

**Step 2: Commit**

```bash
git add lib/features/sync/
git commit -m "feat: add auto-sync trigger mechanism"
```

---

## P2: 标签筛选

### Task 9: 创建标签筛选页面

**Files:**
- Create: `lib/features/diary/presentation/tags_page.dart`

**Step 1: 创建标签页面**

实现功能：
- 显示所有标签及对应日记数量
- 点击标签筛选显示相关日记
- 支持标签管理（重命名、删除）

**Step 2: Commit**

```bash
git add lib/features/diary/presentation/tags_page.dart
git commit -m "feat: add tags filter page"
```

---

## P2: 搜索高亮

### Task 10: 改进搜索功能支持关键词高亮

**Files:**
- Modify: `lib/features/diary/presentation/home_page.dart`
- Modify: `lib/shared/widgets/diary_card.dart`

**Step 1: 修改日记卡片支持高亮**

在 DiaryCard 中添加 `highlightText` 参数，在内容中搜索并高亮匹配文本

**Step 2: Commit**

```bash
git add lib/shared/widgets/diary_card.dart lib/features/diary/presentation/home_page.dart
git commit -m "feat: add search keyword highlighting"
```

---

## P3: 写作目标

### Task 11: 创建写作目标功能

**Files:**
- Create: `lib/features/diary/presentation/goals_page.dart`
- Create: `lib/features/diary/domain/goal_service.dart`

**Step 1: 创建目标服务**

实现功能：
- 设置每日/每周写作目标（字数、篇数）
- 追踪目标完成进度
- 完成提醒

**Step 2: Commit**

```bash
git add lib/features/diary/domain/goal_service.dart lib/features/diary/presentation/goals_page.dart
git commit -m "feat: add writing goals feature"
```

---

## P3: PDF 导出

### Task 12: 添加 PDF 导出功能

**Files:**
- Create: `lib/core/services/pdf_export_service.dart`
- Add dependency: `pdf: ^3.11.0`, `printing: ^5.12.0`

**Step 1: 添加依赖**

```yaml
pdf: ^3.11.0
printing: ^5.12.0
```

**Step 2: 创建 PDF 导出服务**

实现将日记导出为精美 PDF 格式

**Step 3: Commit**

```bash
git add pubspec.yaml lib/core/services/pdf_export_service.dart
git commit -m "feat: add PDF export functionality"
```

---

## 测试与验证

### Task 13: 运行完整测试

**Step 1: 运行 Flutter 分析**

```bash
flutter analyze
```

**Step 2: 运行测试**

```bash
flutter test
```

**Step 3: 构建验证**

```bash
flutter build apk --debug  # Android
flutter build ios --debug  # iOS (需要在 macOS 上)
```

**Step 4: Commit**

```bash
git commit -m "chore: run final verification"
```

---

## 计划完成检查清单

- [ ] P0: Task 1 - 创建草稿服务
- [ ] P0: Task 2 - 集成自动保存
- [ ] P0: Task 3 - 图片支持
- [ ] P1: Task 4 - 创建日历页面
- [ ] P1: Task 5 - 添加日历路由
- [ ] P1: Task 6 - 创建回收站页面
- [ ] P1: Task 7 - 添加回收站路由
- [ ] P2: Task 8 - 自动同步
- [ ] P2: Task 9 - 标签筛选
- [ ] P2: Task 10 - 搜索高亮
- [ ] P3: Task 11 - 写作目标
- [ ] P3: Task 12 - PDF 导出
- [ ] Task 13 - 测试与验证

---

**Plan complete and saved to `docs/plans/2026-03-08-diary-app-improvements.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**