import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

/// 图片服务
class ImageService {
  final ImagePicker _picker = ImagePicker();
  String? _imageDir;

  /// 初始化图片目录
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _imageDir = '${appDir.path}/diary_images';
    
    final dir = Directory(_imageDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 从相册选择图片
  Future<List<String>> pickFromGallery({int maxImages = 9}) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (images.isEmpty) return [];
      
      return await _saveImages(images.map((e) => File(e.path)).toList());
    } catch (e) {
      return [];
    }
  }

  /// 从相机拍照
  Future<String?> pickFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image == null) return null;
      
      final saved = await _saveImages([File(image.path)]);
      return saved.isNotEmpty ? saved.first : null;
    } catch (e) {
      return null;
    }
  }

  /// 保存图片到本地
  Future<List<String>> _saveImages(List<File> images) async {
    if (_imageDir == null) await init();
    
    final savedPaths = <String>[];
    final uuid = const Uuid();
    
    for (final image in images) {
      try {
        final fileName = '${uuid.v4()}.jpg';
        final savedPath = '$_imageDir/$fileName';
        
        await image.copy(savedPath);
        savedPaths.add(savedPath);
      } catch (e) {
        continue;
      }
    }
    
    return savedPaths;
  }

  /// 删除图片
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略删除错误
    }
  }

  /// 批量删除图片
  Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      await deleteImage(path);
    }
  }

  /// 获取图片文件
  Future<File?> getImageFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 检查图片是否存在
  Future<bool> imageExists(String path) async {
    try {
      final file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// 清理未使用的图片
  Future<void> cleanupUnusedImages(List<String> usedPaths) async {
    if (_imageDir == null) await init();
    
    try {
      final dir = Directory(_imageDir!);
      final files = await dir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final path = file.path;
          if (!usedPaths.contains(path)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // 忽略清理错误
    }
  }
}

/// 图片服务 Provider
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});