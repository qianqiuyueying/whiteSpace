import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// 图片选择器组件
class ImagePickerWidget extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    required this.images,
    required this.onAddImage,
    required this.onRemoveImage,
    this.maxImages = 9,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length + (images.length < maxImages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == images.length) {
                  return _buildAddButton(isDark);
                }
                return _buildImageItem(context, images[index], index, isDark);
              },
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          _buildAddButtonLarge(isDark),
        ],
      ],
    );
  }

  Widget _buildImageItem(BuildContext context, String path, int index, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
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
      ),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onAddImage,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(
            Icons.add_photo_alternate_rounded,
            size: 32,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButtonLarge(bool isDark) {
    return GestureDetector(
      onTap: onAddImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 40,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              '添加图片',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图片预览组件
class ImagePreviewGrid extends StatelessWidget {
  final List<String> images;
  final Function(int)? onTap;

  const ImagePreviewGrid({
    super.key,
    required this.images,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.asMap().entries.map((entry) {
        return GestureDetector(
          onTap: () => onTap?.call(entry.key),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(entry.value),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}