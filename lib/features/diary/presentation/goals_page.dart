import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/goal_service.dart';

/// 写作目标页面
class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  List<WritingGoal> _goals = [];
  List<GoalProgress> _progressList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final goalService = ref.read(goalServiceProvider);
    final goals = await goalService.loadGoals();
    final progressList = await goalService.calculateAllProgress();

    if (mounted) {
      setState(() {
        _goals = goals;
        _progressList = progressList;
        _isLoading = false;
      });
    }
  }

  Future<void> _addGoal() async {
    WritingGoal newGoal = const WritingGoal(
      type: GoalType.daily,
      unit: GoalUnit.entries,
      target: 1,
    );

    await showDialog(
      context: context,
      builder: (context) => _GoalEditDialog(
        goal: newGoal,
        onSave: (goal) async {
          setState(() {
            _goals.add(goal);
          });
          final goalService = ref.read(goalServiceProvider);
          await goalService.saveGoals(_goals);
          _loadData();
        },
      ),
    );
  }

  Future<void> _editGoal(int index) async {
    await showDialog(
      context: context,
      builder: (context) => _GoalEditDialog(
        goal: _goals[index],
        onSave: (goal) async {
          setState(() {
            _goals[index] = goal;
          });
          final goalService = ref.read(goalServiceProvider);
          await goalService.saveGoals(_goals);
          _loadData();
        },
      ),
    );
  }

  Future<void> _deleteGoal(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除目标'),
        content: const Text('确定要删除这个写作目标吗？'),
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
      setState(() {
        _goals.removeAt(index);
      });
      final goalService = ref.read(goalServiceProvider);
      await goalService.saveGoals(_goals);
      _loadData();
    }
  }

  Future<void> _toggleGoal(int index, bool enabled) async {
    setState(() {
      _goals[index] = _goals[index].copyWith(enabled: enabled);
    });
    final goalService = ref.read(goalServiceProvider);
    await goalService.saveGoals(_goals);
    _loadData();
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
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
            '写作目标',
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
    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有设置写作目标',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮添加目标',
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        final progress = _progressList.where((p) => p.goal == goal).firstOrNull;

        return _buildGoalCard(goal, progress, index, isDark);
      },
    );
  }

  Widget _buildGoalCard(WritingGoal goal, GoalProgress? progress, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    goal.type.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${goal.target} ${goal.unit.unit}/${goal.type.label}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                ),
                Switch(
                  value: goal.enabled,
                  onChanged: (value) => _toggleGoal(index, value),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          // 进度条
          if (progress != null && goal.enabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progress.progressText,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '${(progress.percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: progress.achieved
                              ? Colors.green
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.percentage,
                      backgroundColor: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress.achieved ? Colors.green : AppTheme.primaryColor,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (progress.achieved)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '目标已达成！',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 操作按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editGoal(index),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('编辑'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _deleteGoal(index),
                  icon: const Icon(Icons.delete_rounded, size: 18),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

/// 目标编辑对话框
class _GoalEditDialog extends StatefulWidget {
  final WritingGoal goal;
  final Function(WritingGoal) onSave;

  const _GoalEditDialog({
    required this.goal,
    required this.onSave,
  });

  @override
  State<_GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<_GoalEditDialog> {
  late GoalType _type;
  late GoalUnit _unit;
  late int _target;

  @override
  void initState() {
    super.initState();
    _type = widget.goal.type;
    _unit = widget.goal.unit;
    _target = widget.goal.target;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置目标'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目标类型
          const Text('目标周期', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GoalType.values.map((t) {
              return ChoiceChip(
                label: Text(t.label),
                selected: _type == t,
                onSelected: (selected) {
                  if (selected) setState(() => _type = t);
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 目标单位
          const Text('目标单位', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GoalUnit.values.map((u) {
              return ChoiceChip(
                label: Text(u.label),
                selected: _unit == u,
                onSelected: (selected) {
                  if (selected) setState(() => _unit = u);
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 目标数量
          const Text('目标数量', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _target > 1 ? () => setState(() => _target--) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                child: Text(
                  '$_target',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _target < 100 ? () => setState(() => _target++) : null,
                icon: const Icon(Icons.add_rounded),
              ),
              Text(_unit.unit),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(WritingGoal(
              type: _type,
              unit: _unit,
              target: _target,
            ));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}