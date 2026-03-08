import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

/// 图片服务
/// 
/// 图片存储策略：
/// - 本地存储：图片以 UUID 命名保存到本地目录
/// - 云同步：图片转为 Base64 存储到 Gist
/// - images 字段存储图片 UUID 列表
class ImageService {
  final ImagePicker _picker = ImagePicker();
  String? _imageDir;
  final _uuid = const Uuid();

  /// 初始化图片目录
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _imageDir = '${appDir.path}/diary_images';

    final dir = Directory(_imageDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 确保图片目录已初始化
  Future<void> _ensureInit() async {
    if (_imageDir == null) await init();
  }

  /// 从相册选择图片
  /// 返回图片 UUID 列表
  Future<List<String>> pickFromGallery({int maxImages = 9}) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 60,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (images.isEmpty) return [];

      return await _saveImages(images.map((e) => File(e.path)).toList());
    } catch (e) {
      return [];
    }
  }

  /// 从相机拍照
  /// 返回图片 UUID
  Future<String?> pickFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1280,
        maxHeight: 1280,
      );

      if (image == null) return null;

      final saved = await _saveImages([File(image.path)]);
      return saved.isNotEmpty ? saved.first : null;
    } catch (e) {
      return null;
    }
  }

  /// 保存图片到本地
  /// 返回图片 UUID 列表
  Future<List<String>> _saveImages(List<File> images) async {
    await _ensureInit();

    final savedUuids = <String>[];

    for (final image in images) {
      try {
        final imageUuid = _uuid.v4();
        final fileName = '$imageUuid.jpg';
        final savedPath = '$_imageDir/$fileName';

        await image.copy(savedPath);
        savedUuids.add(imageUuid);
      } catch (e) {
        continue;
      }
    }

    return savedUuids;
  }

  /// 根据 UUID 获取图片本地路径
  String getImagePath(String uuid) {
    return '$_imageDir/$uuid.jpg';
  }

  /// 根据 UUID 获取图片文件
  Future<File?> getImageFileByUuid(String uuid) async {
    await _ensureInit();
    final path = getImagePath(uuid);
    final file = File(path);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// 检查图片是否存在
  Future<bool> imageExists(String uuid) async {
    await _ensureInit();
    final path = getImagePath(uuid);
    final file = File(path);
    return await file.exists();
  }

  /// 删除图片（根据 UUID）
  Future<void> deleteImage(String uuid) async {
    try {
      final path = getImagePath(uuid);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // 忽略删除错误
    }
  }

  /// 批量删除图片
  Future<void> deleteImages(List<String> uuids) async {
    for (final uuid in uuids) {
      await deleteImage(uuid);
    }
  }

  // ========== 云同步相关方法 ==========

  /// 将图片转换为 Base64 字符串（用于云同步）
  /// 返回 null 表示转换失败
  Future<String?> imageToBase64(String uuid) async {
    try {
      await _ensureInit();
      final path = getImagePath(uuid);
      final file = File(path);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }

  /// 将 Base64 字符串转换为图片并保存到本地
  /// 返回图片 UUID
  Future<String?> base64ToImage(String base64String, {String? uuid}) async {
    try {
      await _ensureInit();
      
      final imageUuid = uuid ?? _uuid.v4();
      final path = getImagePath(imageUuid);
      
      final bytes = base64Decode(base64String);
      final file = File(path);
      await file.writeAsBytes(bytes);
      
      return imageUuid;
    } catch (e) {
      return null;
    }
  }

  /// 批量将图片转换为 Base64（用于云同步）
  /// 返回 Map<uuid, base64String>
  Future<Map<String, String>> imagesToBase64Map(List<String> uuids) async {
    final result = <String, String>{};
    
    for (final uuid in uuids) {
      final base64 = await imageToBase64(uuid);
      if (base64 != null) {
        result[uuid] = base64;
      }
    }
    
    return result;
  }

  /// 批量从 Base64 恢复图片
  /// 返回成功恢复的 UUID 列表
  Future<List<String>> restoreImagesFromBase64(Map<String, String> base64Map) async {
    final restoredUuids = <String>[];
    
    for (final entry in base64Map.entries) {
      final uuid = await base64ToImage(entry.value, uuid: entry.key);
      if (uuid != null) {
        restoredUuids.add(uuid);
      }
    }
    
    return restoredUuids;
  }

  /// 清理未使用的图片
  /// [usedUuids] 仍在使用的图片 UUID 列表
  Future<void> cleanupUnusedImages(List<String> usedUuids) async {
    await _ensureInit();

    try {
      final dir = Directory(_imageDir!);
      final files = await dir.list().toList();

      for (final file in files) {
        if (file is File) {
          // 从文件名提取 UUID（去掉 .jpg 后缀）
          final fileName = file.uri.pathSegments.last;
          final uuid = fileName.replaceAll('.jpg', '');
          
          if (!usedUuids.contains(uuid)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // 忽略清理错误
    }
  }

  /// 获取图片目录路径
  Future<String?> getImageDirectory() async {
    await _ensureInit();
    return _imageDir;
  }
}

/// 图片服务 Provider
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});