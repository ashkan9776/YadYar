import 'package:flutter/material.dart';

/// آیکون‌های از پیش تعریف‌شده برای دسته‌بندی‌ها.
/// ایندکس انتخاب‌شده در مدل Category ذخیره می‌شود.
class CategoryIcons {
  CategoryIcons._();

  static const icons = <IconData>[
    Icons.record_voice_over, // 0 - Speaking
    Icons.headphones, // 1 - Listening
    Icons.menu_book, // 2 - Reading
    Icons.edit_note, // 3 - Writing
    Icons.spellcheck, // 4 - Grammar
    Icons.translate, // 5 - Vocabulary
    Icons.category, // 6 - General
    Icons.folder, // 7 - Other
    Icons.school, // 8 - Education
    Icons.science, // 9 - Science
    Icons.history_edu, // 10 - History
    Icons.public, // 11 - Geography
  ];

  /// آیکون متناظر با ایندکس (با محافظت در برابر خارج از بازه).
  static IconData iconAt(int index) {
    if (index < 0 || index >= icons.length) return Icons.category;
    return icons[index];
  }
}
