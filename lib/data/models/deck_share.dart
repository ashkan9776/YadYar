import 'dart:convert';

/// فرمت اشتراک‌گذاری دک — فقط عنوان، توضیحات، رنگ و کارت‌ها.
/// فاقد اطلاعات زمان‌بندی و مرور (schedule تمیز برای شروع تازه).
class DeckShare {
  const DeckShare({
    required this.title,
    required this.description,
    required this.colorHex,
    required this.cards,
  });

  final String title;
  final String? description;
  final int colorHex;

  /// لیست کارت‌ها: هر کدام شامل front و back.
  final List<({String front, String back})> cards;

  /// تبدیل به JSON رشته‌ای (برای اشتراک‌گذاری).
  String toJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'یادیار',
      'type': 'deck',
      'title': title,
      'description': description,
      'colorHex': colorHex,
      'cards': cards
          .map((c) => {'front': c.front, 'back': c.back})
          .toList(),
    });
  }

  /// تجزیه‌ی JSON به دک قابل اشتراک‌گذاری.
  factory DeckShare.fromJson(String source) {
    final data = json.decode(source) as Map<String, dynamic>;
    final cardsList = (data['cards'] as List<dynamic>)
        .map((e) => (
              front: (e as Map<String, dynamic>)['front'] as String? ?? '',
              back: e['back'] as String? ?? '',
            ))
        .where((c) => c.front.isNotEmpty && c.back.isNotEmpty)
        .toList();
    return DeckShare(
      title: data['title'] as String? ?? 'دک بدون نام',
      description: data['description'] as String?,
      colorHex: data['colorHex'] as int? ?? 0xFF7F77DD,
      cards: cardsList,
    );
  }
}
