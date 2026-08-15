import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/deck.dart';
import '../../providers/providers.dart';

/// کتابخانه‌ی دک‌ها.
class DecksPage extends ConsumerWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksStreamProvider);
    final dueCounts = ref.watch(dueCountsProvider);
    final cardCounts = ref.watch(cardCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('دک‌های من')),
      body: SafeArea(
        child: decksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا: $e')),
          data: (decks) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              for (final deck in decks)
                _DeckCard(
                  deck: deck,
                  total: cardCounts[deck.id] ?? 0,
                  due: dueCounts[deck.id] ?? 0,
                ),
              const SizedBox(height: 4),
              _NewDeckTile(onTap: () => context.push('/deck-new')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard(
      {required this.deck, required this.total, required this.due});
  final Deck deck;
  final int total;
  final int due;

  @override
  Widget build(BuildContext context) {
    final color = Color(deck.colorHex);
    final subtitle = total == 0
        ? 'بدون کارت'
        : due > 0
            ? '${Fa.digits(total)} کارت — ${Fa.digits(due)} کارت امروز'
            : '${Fa.digits(total)} کارت — تمام شد ✓';

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(Fa.digits(due),
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

class _NewDeckTile extends StatelessWidget {
  const _NewDeckTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.colors.border2,
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text('+ دک جدید',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary)),
        ),
      ),
    );
  }
}
