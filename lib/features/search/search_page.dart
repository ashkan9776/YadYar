import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/deck.dart';
import '../../data/models/flashcard.dart';
import '../../domain/answer_match.dart';
import '../../providers/providers.dart';

/// صفحه‌ی جست‌وجوی سراسری — جستجو در روی و پشت همه‌ی فلش‌کارت‌ها.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _queryController = TextEditingController();
  String _query = '';
  bool _hasSearched = false;

  /// فیلتر کارت‌ها بر اساس عبارت جستجو — تطبیق روی + پشت.
  List<FlashCard> _filterCards(List<FlashCard> cards) {
    if (_query.isEmpty) return const [];
    final normalizedQuery = AnswerMatcher.normalize(_query);
    return cards.where((card) {
      final frontNorm = AnswerMatcher.normalize(card.front);
      final backNorm = AnswerMatcher.normalize(card.back);
      return frontNorm.contains(normalizedQuery) ||
          backNorm.contains(normalizedQuery);
    }).toList();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(allCardsStreamProvider).value ?? const [];
    final decks = ref.watch(decksStreamProvider).value ?? const [];
    final deckMap = <int, Deck>{for (final d in decks) d.id!: d};

    final results = _hasSearched ? _filterCards(cards) : <FlashCard>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('جستجو'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close),
            tooltip: 'بستن',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // فیلد جستجو
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.bg2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded,
                        color: context.colors.textMuted, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        autofocus: true,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                            fontSize: 15, color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'جستجو در کارت‌ها...',
                          hintStyle: TextStyle(
                              color: context.colors.textMuted, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _query = value.trim();
                            _hasSearched = true;
                          });
                        },
                        onSubmitted: (_) {
                          setState(() => _hasSearched = true);
                        },
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _queryController.clear();
                          setState(() {
                            _query = '';
                            _hasSearched = false;
                          });
                        },
                        icon: Icon(Icons.close_rounded,
                            color: context.colors.textMuted, size: 20),
                        tooltip: 'پاک کردن',
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            // نتایج جستجو
            Expanded(
              child: !_hasSearched
                  ? Center(
                      child: Text('عبارت مورد نظرت رو تایپ کن',
                          style: TextStyle(
                              fontSize: 14, color: context.colors.textMuted)))
                  : results.isEmpty && _query.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48, color: context.colors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'کارتی با «$_query» پیدا نشد',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: context.colors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final card = results[index];
                            final deck =
                                deckMap[card.deckId];
                            return _ResultTile(
                              card: card,
                              deck: deck,
                              query: _query,
                              onTap: () {
                                // رفتن به جزئیات دک
                                if (card.deckId > 0) {
                                  context.pop();
                                  context.push('/deck/${card.deckId}');
                                }
                              },
                            );
                          },
                        ),
            ),

            // تعداد نتایج
            if (_hasSearched && results.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: context.colors.bg,
                child: Text(
                  '${Fa.digits(results.length)} نتیجه یافت شد',
                  style: TextStyle(
                      fontSize: 12, color: context.colors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// یک ردیف نتیجه‌ی جستجو — روی/پشت کارت + نام دک.
class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.card,
    required this.deck,
    required this.query,
    required this.onTap,
  });
  final FlashCard card;
  final Deck? deck;
  final String query;
  final VoidCallback onTap;

  /// رنگ کارت‌های دک از پالت رنگی.
  Color _deckColor(int colorHex) {
    final palette = AppColors.deckPalette;
    final hex = palette[colorHex % palette.length];
    return Color(hex);
  }

  /// برجسته‌سازی متن‌های منطبق با عبارت جستجو.
  RichText _highlight(String text, BuildContext context) {
    if (query.isEmpty) {
      return RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 13, color: context.colors.textPrimary),
        ),
      );
    }

    final normalizedText = AnswerMatcher.normalize(text);
    final normalizedQuery = AnswerMatcher.normalize(query);
    final spans = <TextSpan>[];
    int lastEnd = 0;

    int idx = normalizedText.indexOf(normalizedQuery, lastEnd);
    while (idx != -1) {
      // بخش قبل از تطبیق.
      if (idx > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, idx),
          style: TextStyle(
              fontSize: 13, color: context.colors.textPrimary),
        ));
      }
      // بخش منطبق — با رنگ تأکید.
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.colors.accent),
      ));
      lastEnd = idx + query.length;
      idx = normalizedText.indexOf(normalizedQuery, lastEnd);
    }

    // بخش باقی‌مانده.
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(
            fontSize: 13, color: context.colors.textPrimary),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final deckColor =
        deck != null ? _deckColor(deck!.colorHex) : c.accent;
    final deckTitle = deck?.title ?? 'بدون دک';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: c.bg2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نام دک با نقطه‌ی رنگی.
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: deckColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deckTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // روی کارت.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('رو:',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted)),
                  ),
                  Expanded(child: _highlight(card.front, context)),
                ],
              ),
              const SizedBox(height: 6),
              // پشت کارت.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('پشت:',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: c.textMuted)),
                  ),
                  Expanded(child: _highlight(card.back, context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
