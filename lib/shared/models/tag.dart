/// 标签模型
class Tag {
  final String name;
  final int colorIndex;
  final int count;

  const Tag({
    required this.name,
    this.colorIndex = 0,
    this.count = 0,
  });

  Tag copyWith({
    String? name,
    int? colorIndex,
    int? count,
  }) {
    return Tag(
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
      count: count ?? this.count,
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] ?? '',
      colorIndex: json['colorIndex'] ?? 0,
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorIndex': colorIndex,
      'count': count,
    };
  }
}