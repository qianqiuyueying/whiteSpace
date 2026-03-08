import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Markdown 编辑器模式
enum EditorMode {
  edit,
  preview,
  split,
}

/// Markdown 编辑器组件
class MarkdownEditor extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final bool showPreview;
  final VoidCallback? onImageTap;
  final ValueChanged<String>? onChanged;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.hintText,
    this.showPreview = false,
    this.onImageTap,
    this.onChanged,
  });

  @override
  ConsumerState<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends ConsumerState<MarkdownEditor> {
  EditorMode _mode = EditorMode.edit;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _insertMarkdown(String before, [String after = '']) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.start;
    final end = selection.end;

    String newText;
    int newCursorPos;

    if (start == end) {
      // 没有选中文本
      newText = text.substring(0, start) + before + after + text.substring(start);
      newCursorPos = start + before.length;
    } else {
      // 有选中文本
      final selectedText = text.substring(start, end);
      newText = text.substring(0, start) + before + selectedText + after + text.substring(end);
      newCursorPos = start + before.length + selectedText.length + after.length;
    }

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(offset: newCursorPos);
    widget.onChanged?.call(newText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // 工具栏
        _buildToolbar(isDark),

        const SizedBox(height: 8),

        // 编辑/预览区域
        Expanded(
          child: _buildEditorArea(isDark),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 格式按钮
          _buildToolButton(Icons.format_bold_rounded, () => _insertMarkdown('**', '**'), isDark),
          _buildToolButton(Icons.format_italic_rounded, () => _insertMarkdown('*', '*'), isDark),
          _buildToolButton(Icons.strikethrough_s_rounded, () => _insertMarkdown('~~', '~~'), isDark),
          _buildToolButton(Icons.code_rounded, () => _insertMarkdown('`', '`'), isDark),
          _buildToolButton(Icons.format_quote_rounded, () => _insertMarkdown('> '), isDark),
          _buildToolButton(Icons.link_rounded, () => _insertMarkdown('[', '](url)'), isDark),
          _buildToolButton(Icons.image_rounded, widget.onImageTap ?? () {}, isDark),
          _buildToolButton(Icons.checklist_rounded, () => _insertMarkdown('- [ ] '), isDark),

          const Spacer(),

          // 模式切换
          _buildModeToggle(isDark),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, VoidCallback onTap, bool isDark) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 20,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
      splashRadius: 20,
      tooltip: _getTooltip(icon),
    );
  }

  String _getTooltip(IconData icon) {
    switch (icon) {
      case Icons.format_bold_rounded:
        return '粗体';
      case Icons.format_italic_rounded:
        return '斜体';
      case Icons.strikethrough_s_rounded:
        return '删除线';
      case Icons.code_rounded:
        return '代码';
      case Icons.format_quote_rounded:
        return '引用';
      case Icons.link_rounded:
        return '链接';
      case Icons.image_rounded:
        return '图片';
      case Icons.checklist_rounded:
        return '待办';
      default:
        return '';
    }
  }

  Widget _buildModeToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(Icons.edit_rounded, EditorMode.edit, isDark),
          _buildModeButton(Icons.visibility_rounded, EditorMode.preview, isDark),
          _buildModeButton(Icons.view_column_rounded, EditorMode.split, isDark),
        ],
      ),
    );
  }

  Widget _buildModeButton(IconData icon, EditorMode mode, bool isDark) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? Colors.white
              : isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildEditorArea(bool isDark) {
    switch (_mode) {
      case EditorMode.edit:
        return _buildTextField(isDark);
      case EditorMode.preview:
        return _buildPreview(isDark);
      case EditorMode.split:
        return Row(
          children: [
            Expanded(child: _buildTextField(isDark)),
            Container(width: 1, color: isDark ? AppTheme.darkCard : AppTheme.lightCard),
            Expanded(child: _buildPreview(isDark)),
          ],
        );
    }
  }

  Widget _buildTextField(bool isDark) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: TextStyle(
        fontSize: 16,
        height: 1.8,
        fontFamily: 'monospace',
        color: isDark ? AppTheme.darkText : AppTheme.lightText,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText ?? '使用 Markdown 格式书写...',
        hintStyle: TextStyle(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        border: InputBorder.none,
        filled: true,
        fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        contentPadding: const EdgeInsets.all(16),
      ),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildPreview(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: MarkdownBody(
        data: widget.controller.text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: 16,
            height: 1.8,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          h1: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          h2: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          h3: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
          blockquote: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontStyle: FontStyle.italic,
          ),
          code: TextStyle(
            backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(8),
          ),
          listBullet: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
    );
  }
}