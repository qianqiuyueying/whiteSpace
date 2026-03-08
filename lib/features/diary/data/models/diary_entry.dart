import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'diary_entry.g.dart';

/// 日记条目模型
@collection
class DiaryEntry {
  Id id = Isar.autoIncrement;

  /// 唯一标识符
  @Index(unique: true)
  late String uuid;

  /// 标题
  String? title;

  /// 内容 (Markdown 格式)
  late String content;

  /// 心情 (对应 Mood enum index)
  int moodIndex = 7; // 默认 neutral

  /// 天气 (对应 Weather enum index)
  int? weatherIndex;

  /// 标签列表 (JSON 字符串)
  List<String> tags = [];

  /// 图片路径列表 (JSON 字符串)
  List<String> images = [];

  /// 创建时间
  late DateTime createdAt;

  /// 更新时间
  late DateTime updatedAt;

  /// 是否已同步到云端
  bool isSynced = false;

  /// 是否已删除 (软删除)
  bool isDeleted = false;

  /// Gist 文件 ID (用于同步)
  String? gistFileId;

  /// 位置信息
  String? location;

  DiaryEntry() {
    uuid = const Uuid().v4();
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// 从 JSON 创建
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final entry = DiaryEntry();
    entry.uuid = json['uuid'] ?? const Uuid().v4();
    entry.title = json['title'];
    entry.content = json['content'] ?? '';
    entry.moodIndex = json['moodIndex'] ?? 7;
    entry.weatherIndex = json['weatherIndex'];
    entry.tags = List<String>.from(json['tags'] ?? []);
    entry.images = List<String>.from(json['images'] ?? []);
    entry.createdAt = DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String());
    entry.updatedAt = DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String());
    entry.isSynced = json['isSynced'] ?? false;
    entry.isDeleted = json['isDeleted'] ?? false;
    entry.gistFileId = json['gistFileId'];
    entry.location = json['location'];
    return entry;
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'content': content,
      'moodIndex': moodIndex,
      'weatherIndex': weatherIndex,
      'tags': tags,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'isDeleted': isDeleted,
      'gistFileId': gistFileId,
      'location': location,
    };
  }

  /// 创建副本
  DiaryEntry copyWith({
    String? uuid,
    String? title,
    String? content,
    int? moodIndex,
    int? weatherIndex,
    List<String>? tags,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
    String? gistFileId,
    String? location,
  }) {
    return DiaryEntry()
      ..uuid = uuid ?? this.uuid
      ..title = title ?? this.title
      ..content = content ?? this.content
      ..moodIndex = moodIndex ?? this.moodIndex
      ..weatherIndex = weatherIndex ?? this.weatherIndex
      ..tags = tags ?? List.from(this.tags)
      ..images = images ?? List.from(this.images)
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt
      ..isSynced = isSynced ?? this.isSynced
      ..isDeleted = isDeleted ?? this.isDeleted
      ..gistFileId = gistFileId ?? this.gistFileId
      ..location = location ?? this.location;
  }
}