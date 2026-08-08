/// یک دسته‌بندی سطح بالا (مثلاً Speaking, Grammar, Vocabulary).
class Category {
  const Category({
    this.id,
    required this.title,
    this.description,
    required this.iconIndex,
    required this.colorHex,
    required this.createdAt,
    this.isBuiltIn = false,
    this.sortOrder = 0,
  });

  /// شناسه یکتا (کلید سِم‌بَست). برای دسته ذخیره‌نشده null است.
  final int? id;
  final String title;
  final String? description;
  final int iconIndex;
  final int colorHex;
  final DateTime createdAt;
  final bool isBuiltIn;
  final int sortOrder;

  Category copyWith({
    int? id,
    String? title,
    String? description,
    int? iconIndex,
    int? colorHex,
    DateTime? createdAt,
    bool? isBuiltIn,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconIndex: iconIndex ?? this.iconIndex,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => {
        'title': title,
        'description': description,
        'iconIndex': iconIndex,
        'colorHex': colorHex,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isBuiltIn': isBuiltIn,
        'sortOrder': sortOrder,
      };

  factory Category.fromMap(int id, Map<String, Object?> map) => Category(
        id: id,
        title: map['title'] as String,
        description: map['description'] as String?,
        iconIndex: (map['iconIndex'] as int?) ?? 0,
        colorHex: map['colorHex'] as int,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        isBuiltIn: (map['isBuiltIn'] as bool?) ?? false,
        sortOrder: (map['sortOrder'] as int?) ?? 0,
      );
}
