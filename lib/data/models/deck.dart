/// یک دک (مجموعه فلش‌کارت). مطابق جدول Deck در PRD.
class Deck {
  const Deck({
    this.id,
    required this.title,
    this.description,
    required this.colorHex,
    required this.createdAt,
    this.isBuiltIn = false,
  });

  /// شناسه یکتا (کلید سِم‌بَست). برای دک ذخیره‌نشده null است.
  final int? id;
  final String title;
  final String? description;
  final int colorHex;
  final DateTime createdAt;
  final bool isBuiltIn;

  Deck copyWith({
    int? id,
    String? title,
    String? description,
    int? colorHex,
    DateTime? createdAt,
    bool? isBuiltIn,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  Map<String, Object?> toMap() => {
        'title': title,
        'description': description,
        'colorHex': colorHex,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isBuiltIn': isBuiltIn,
      };

  factory Deck.fromMap(int id, Map<String, Object?> map) => Deck(
        id: id,
        title: map['title'] as String,
        description: map['description'] as String?,
        colorHex: map['colorHex'] as int,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        isBuiltIn: (map['isBuiltIn'] as bool?) ?? false,
      );
}
