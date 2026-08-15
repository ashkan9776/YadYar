import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/services/freemium_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/deck.dart';
import '../../data/models/deck_share.dart';
import '../../data/services/csv_import_service.dart';
import '../../features/premium/premium_dialog.dart';
import '../../providers/providers.dart';

/// جزئیات یک کتاب: لیست دک‌های زیرمجموعه.
class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.bookId});
  final int bookId;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  bool _importing = false;

  /// انتخاب فایل و وارد کردن دک زیر همین کتاب.
  /// فرمت‌ها: JSON (اشتراک‌گذاری یادیار) و CSV/TXT (خروجی Anki و Quizlet).
  Future<void> _importDeck() async {
    final isPro = ref.read(isProProvider);
    final deckCount = ref.read(deckCountProvider(widget.bookId));

    // بررسی محدودیت نسخه رایگان قبل از انتخاب فایل.
    if (!FreemiumLimits.canCreateDeck(deckCount, isPro)) {
      if (mounted) {
        showPremiumDialog(context, ref,
            reason: FreemiumLimits.limitMessage('deck'));
      }
      return;
    }

    setState(() => _importing = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      // خروجی Anki/Quizlet معمولاً UTF-8 است؛ فایل‌های معیوب crash نکنند.
      final content =
          utf8.decode(await file.readAsBytes(), allowMalformed: true);

      final ext = fileName.toLowerCase().split('.').last;
      var share = ext == 'json'
          ? DeckShare.fromJson(content)
          : CsvImportService.parse(content, fileName: fileName);

      // اعتبارسنجی ساده.
      if (share.cards.isEmpty) {
        throw Exception('فایل فاقد کارت معتبر است');
      }

      // سقف کارت نسخه رایگان: ۵۰ کارت اول + اطلاع به کاربر.
      var truncated = false;
      if (!isPro && share.cards.length > FreemiumLimits.maxCardsPerDeck) {
        truncated = true;
        share = DeckShare(
          title: share.title,
          description: share.description,
          colorHex: share.colorHex,
          cards: share.cards.take(FreemiumLimits.maxCardsPerDeck).toList(),
        );
      }

      final service = ref.read(deckShareServiceProvider);
      final newDeckId =
          await service.importDeck(share, bookId: widget.bookId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(truncated
              ? 'دک «${share.title}» با ${Fa.digits(share.cards.length)} کارت وارد شد (سقف نسخه رایگان) 👑'
              : 'دک «${share.title}» با ${Fa.digits(share.cards.length)} کارت وارد شد ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // باز کردن دک واردشده.
      if (mounted) context.push('/deck/$newDeckId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در وارد کردن دک: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksStreamProvider).value ?? const [];
    final book = books.where((b) => b.id == widget.bookId).firstOrNull;
    final decksAsync = ref.watch(bookDecksProvider(widget.bookId));
    final dueCounts = ref.watch(dueCountsProvider);
    final cardCounts = ref.watch(cardCountsProvider);
    final isPro = ref.watch(isProProvider);
    final deckCount = ref.watch(deckCountProvider(widget.bookId));

    final color = book == null ? context.colors.accent : Color(book.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(book?.title ?? 'کتاب'),
        actions: [
          IconButton(
            icon: _importing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            tooltip: 'وارد کردن دک',
            onPressed: _importing ? null : _importDeck,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ویرایش کتاب',
            onPressed: () => context.push('/book/${widget.bookId}/edit'),
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
            context.push('/book/${widget.bookId}/deck-new');
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
      await ref.read(bookRepositoryProvider).delete(widget.bookId);
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
              Icon(Icons.chevron_right_rounded,
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
