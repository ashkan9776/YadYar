import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/services/freemium_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/category_icons.dart';
import '../../data/models/book.dart';
import '../../features/premium/premium_dialog.dart';
import '../../providers/providers.dart';

/// جزئیات یک دسته‌بندی: لیست کتاب‌های زیرمجموعه.
class CategoryDetailPage extends ConsumerWidget {
  const CategoryDetailPage({super.key, required this.categoryId});
  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesStreamProvider).value ?? const [];
    final category = cats.where((c) => c.id == categoryId).firstOrNull;
    final booksAsync = ref.watch(categoryBooksProvider(categoryId));
    final bookCardCounts = ref.watch(bookCardCountsProvider);
    final bookDueCounts = ref.watch(bookDueCountsProvider);
    final decks = ref.watch(decksStreamProvider).value ?? const [];
    final isPro = ref.watch(isProProvider);
    final bookCount = ref.watch(bookCountProvider(categoryId));

    final color =
        category == null ? context.colors.accent : Color(category.colorHex);
    final icon = category == null
        ? Icons.category
        : CategoryIcons.iconAt(category.iconIndex);

    // شمارش تعداد دک‌های هر کتاب.
    final deckCountByBook = <int, int>{};
    for (final d in decks) {
      deckCountByBook[d.bookId] = (deckCountByBook[d.bookId] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.title ?? 'دسته‌بندی'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ویرایش دسته',
            onPressed: () => context.push('/category/$categoryId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'حذف دسته',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(isPro
            ? 'کتاب جدید'
            : 'کتاب جدید (${Fa.digits(bookCount)}/${Fa.digits(FreemiumLimits.maxBooksPerCategory)})'),
        onPressed: () {
          if (!FreemiumLimits.canCreateBook(bookCount, isPro)) {
            showPremiumDialog(context, ref,
                reason: FreemiumLimits.limitMessage('book'));
          } else {
            context.push('/category/$categoryId/book-new');
          }
        },
      ),
      body: SafeArea(
        child: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا: $e')),
          data: (books) {
            if (category == null) {
              return Center(
                  child: Text('دسته‌بندی یافت نشد',
                      style: TextStyle(color: context.colors.textMuted)));
            }
            return Column(
              children: [
                if (category.description != null &&
                    category.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(category.description!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: books.isEmpty
                      ? const _NoBooks()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                          children: [
                            for (final book in books)
                              _BookRow(
                                book: book,
                                color: color,
                                deckCount: deckCountByBook[book.id] ?? 0,
                                cardCount: bookCardCounts[book.id] ?? 0,
                                dueCount: bookDueCounts[book.id] ?? 0,
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دسته‌بندی'),
        content: const Text(
            'این دسته‌بندی و همه‌ی کتاب‌ها، دک‌ها و کارت‌های زیرمجموعه‌اش حذف می‌شوند. مطمئنی؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف', style: TextStyle(color: context.colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(categoryRepositoryProvider).delete(categoryId);
      if (context.mounted) context.pop();
    }
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({
    required this.book,
    required this.color,
    required this.deckCount,
    required this.cardCount,
    required this.dueCount,
  });
  final Book book;
  final Color color;
  final int deckCount;
  final int cardCount;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final bookColor = Color(book.colorHex);
    final subtitle = cardCount == 0
        ? (deckCount == 0 ? 'خالی' : '$deckCount دک')
        : dueCount > 0
            ? '$deckCount دک — $dueCount کارت امروز'
            : '$deckCount دک — تمام شد ✓';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/book/${book.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bookColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border(right: BorderSide(color: bookColor, width: 3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bookColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.menu_book_outlined, color: bookColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: bookColor)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textMuted)),
                  ],
                ),
              ),
              if (dueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: bookColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('$dueCount',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoBooks extends StatelessWidget {
  const _NoBooks();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'این دسته هنوز کتابی نداره.\nبا دکمه «کتاب جدید» اولین کتاب رو بساز.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted),
        ),
      ),
    );
  }
}
