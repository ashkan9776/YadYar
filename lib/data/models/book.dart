/// یک کتاب (مجموعه‌ای از دک‌ها) که زیرمجموعه‌ی یک دسته‌بندی است.
class Book {
  const Book({
    this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.colorHex,
    required this.createdAt,
    this.isBuiltIn = false,
    this.sortOrder = 0,
  });

  /// شناسه یکتا (کلید سِم‌بَست). برای کتاب ذخیره‌نشده null است.
  final int? id;
  final int categoryId;
  final String title;
  final String? description;
  final int colorHex;
  final DateTime createdAt;
  final bool isBuiltIn;
  final int sortOrder;

  Book copyWith({
    int? id,
    int? categoryId,
    String? title,
    String? description,
    int? colorHex,
    DateTime? createdAt,
    bool? isBuiltIn,
    int? sortOrder,
  }) {
    return Book(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => {
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'colorHex': colorHex,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isBuiltIn': isBuiltIn,
        'sortOrder': sortOrder,
      };

  factory Book.fromMap(int id, Map<String, Object?> map) => Book(
        id: id,
        categoryId: map['categoryId'] as int,
        title: map['title'] as String,
        description: map['description'] as String?,
        colorHex: map['colorHex'] as int,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        isBuiltIn: (map['isBuiltIn'] as bool?) ?? false,
        sortOrder: (map['sortOrder'] as int?) ?? 0,
      );
}
