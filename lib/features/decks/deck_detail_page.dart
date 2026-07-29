import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/math_text.dart';
import '../../data/models/deck.dart';
import '../../data/models/flashcard.dart';
import '../../providers/providers.dart';
import '../review/review_controller.dart';
import 'card_editor_sheet.dart';

/// جزئیات یک دک: لیست کارت‌ها، مرور، افزودن/ویرایش/حذف کارت.
class DeckDetailPage extends ConsumerWidget {
  const DeckDetailPage({super.key, required this.deckId});
  final int deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksStreamProvider).value ?? const [];
    final deck = decks.where((d) => d.id == deckId).firstOrNull;
    final cardsAsync = ref.watch(deckCardsProvider(deckId));
    final due = ref.watch(dueCountsProvider)[deckId] ?? 0;

    final color = deck == null ? context.colors.accent : Color(deck.colorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(deck?.title ?? 'دک'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'اشتراک‌گذاری دک',
            onPressed: deck == null
                ? null
                : () => _shareDeck(context, ref, deck),
          ),
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            tooltip: 'آزمون چندگزینه‌ای',
            onPressed: () => context.push('/quiz/$deckId'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ویرایش دک',
            onPressed: () => context.push('/deck/$deckId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'حذف دک',
            onPressed: () => _confirmDeleteDeck(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('کارت جدید'),
        onPressed: () => showCardEditorSheet(context, ref, deckId: deckId),
      ),
      body: SafeArea(
        child: cardsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا: $e')),
          data: (cards) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          due > 0
                              ? '${Fa.digits(due)} کارت برای مرور امروز'
                              : '${Fa.digits(cards.length)} کارت — امروز کامل شد',
                          style: TextStyle(
                              color: context.colors.textSecondary, fontSize: 13),
                        ),
                      ),
                      if (cards.isNotEmpty)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(color: color.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          onPressed: () =>
                              context.push('/review/${cramId(deckId)}'),
                          child: const Text('مرور فوری', style: TextStyle(fontSize: 13)),
                        ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: due > 0 ? color : context.colors.bg3,
                          foregroundColor:
                              due > 0 ? Colors.white : context.colors.textMuted,
                        ),
                        onPressed: due > 0
                            ? () => context.push('/review/$deckId')
                            : null,
                        child: const Text('شروع مرور'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: context.colors.border),
                Expanded(
                  child: cards.isEmpty
                      ? const _NoCards()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                          itemCount: cards.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _CardTile(
                            card: cards[i],
                            color: color,
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDeck(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف دک'),
        content: const Text(
            'این دک و همه‌ی کارت‌هایش حذف می‌شوند. مطمئنی؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('حذف',
                  style: TextStyle(color: context.colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(deckRepositoryProvider).delete(deckId);
      if (context.mounted) context.pop();
    }
  }

  /// اشتراک‌گذاری دک به‌صورت فایل JSON.
  Future<void> _shareDeck(
      BuildContext context, WidgetRef ref, Deck deck) async {
    try {
      final service = ref.read(deckShareServiceProvider);
      final share = await service.exportDeck(
        deckId: deckId,
        title: deck.title,
        description: deck.description,
        colorHex: deck.colorHex,
      );

      // ذخیره در فایل موقت و اشتراک‌گذاری.
      final dir = await getTemporaryDirectory();
      final safeName = deck.title.replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9]'), '_');
      final file = File('${dir.path}/yadyar_deck_$safeName.json');
      await file.writeAsString(share.toJson());

      final xFile = XFile(file.path, name: 'yadyar_deck_$safeName.json');
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile],
          text: 'دک «${deck.title}» — ${Fa.digits(share.cards.length)} کارت');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('دک برای اشتراک‌گذاری آماده شد ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در اشتراک‌گذاری: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card, required this.color});
  final FlashCard card;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: context.colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline_rounded, color: context.colors.red),
      ),
      confirmDismiss: (_) async {
        await ref.read(cardRepositoryProvider).delete(card.id!);
        return true;
      },
      child: InkWell(
        onTap: () => showCardEditorSheet(context, ref,
            deckId: card.deckId, existing: card),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.bg2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MathText(card.front,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary)),
              const SizedBox(height: 6),
              MathText(card.back,
                  style: TextStyle(
                      fontSize: 13, color: context.colors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(
                      card.isNew
                          ? 'جدید'
                          : 'مرور بعدی: ${Fa.fullDate(card.nextReview)}',
                      color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _NoCards extends StatelessWidget {
  const _NoCards();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'این دک هنوز کارتی نداره.\nبا دکمه «کارت جدید» اولین کارت رو بساز.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted),
        ),
      ),
    );
  }
}
