import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/services/freemium_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/deck.dart';
import '../../features/premium/premium_dialog.dart';
import '../../providers/providers.dart';

/// جزئیات یک کتاب: لیست دک‌های زیرمجموعه.
class BookDetailPage extends ConsumerWidget {
  const BookDetailPage({super.key, required this.bookId});
  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksStreamProvider).value ?? const [];
    final book = books.where((b) => b.id == bookId).firstOrNull;
    final decksAsync = ref.watch(bookDecksProvider(bookId));
    final dueCounts = ref.watch(dueCountsProvider);
    final cardCounts = ref.watch(cardCountsProvider);
    final isPro = ref.watch(isProProvider);
    final deckCount = ref.watch(deckCountProvider(bookId));

    final color = book == null ? context.colors.accent : Color(book.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? 'کتاب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ویرایش کتاب',
            onPressed: () => context.push('/book/$bookId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'حذف کتاب',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(isPro
            ? 'دک جدید'
            : 'دک جدید (${Fa.digits(deckCount)}/${Fa.digits(FreemiumLimits.maxDecksPerBook)})'),
        onPressed: () {
          if (!FreemiumLimits.canCreateDeck(deckCount, isPro)) {
            showPremiumDialog(context, ref,
                reason: FreemiumLimits.limitMessage('deck'));
          } else {
            context.push('/book/$bookId/deck-new');
          }
        },
      ),
      body: SafeArea(
        child: decksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا: $e')),
          data: (decks) {
            if (book == null) {
              return Center(
                  child: Text('کتاب یافت نشد',
                      style: TextStyle(color: context.colors.textMuted)));
            }
            return Column(
              children: [
                if (book.description != null && book.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(book.description!,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: decks.isEmpty
                      ? const _NoDecks()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                          children: [
                            for (final deck in decks)
                              _DeckRow(
                                deck: deck,
                                total: cardCounts[deck.id] ?? 0,
                                due: dueCounts[deck.id] ?? 0,
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
        title: const Text('حذف کتاب'),
        content: const Text(
            'این کتاب و همه‌ی دک‌ها و کارت‌های زیرمجموعه‌اش حذف می‌شوند. مطمئنی؟'),
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
      await ref.read(bookRepositoryProvider).delete(bookId);
      if (context.mounted) context.pop();
    }
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.total, required this.due});
  final Deck deck;
  final int total;
  final int due;

  @override
  Widget build(BuildContext context) {
    final color = Color(deck.colorHex);
    final subtitle = total == 0
        ? 'بدون کارت'
        : due > 0
            ? '$total کارت — $due کارت امروز'
            : '$total کارت — تمام شد ✓';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/deck/${deck.id}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border(right: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.style_outlined, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textMuted)),
                  ],
                ),
              ),
              if (due > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('$due',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_left_rounded,
                  color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoDecks extends StatelessWidget {
  const _NoDecks();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'این کتاب هنوز دکی نداره.\nبا دکمه «دک جدید» اولین دک رو بساز.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted),
        ),
      ),
    );
  }
}
