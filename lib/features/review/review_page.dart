import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/math_text.dart';
import '../../data/models/rating.dart';
import '../../providers/providers.dart';
import 'review_controller.dart';
import 'widgets/flip_card.dart';

/// صفحه‌ی مرور فلش‌کارت — قلب اپ.
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key, required this.deckId});
  final int deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewControllerProvider(deckId));
    final controller = ref.read(reviewControllerProvider(deckId).notifier);
    final typedMode = ref.watch(settingsProvider).typedAnswerMode;

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.cards.isEmpty) {
      body = const _EmptyView();
    } else if (state.finished) {
      body = Stack(
        children: [
          _SummaryView(
            hard: state.hard,
            good: state.good,
            easy: state.easy,
            focusEnded: state.focusEnded,
          ),
          const Positioned.fill(child: ConfettiBurst()),
        ],
      );
    } else if (typedMode) {
      body = _TypedReviewBody(state: state, controller: controller);
    } else {
      body = _ReviewBody(state: state, controller: controller);
    }

    return Scaffold(
      appBar: AppBar(
        title: state.focusActive
            ? _FocusTitle(seconds: state.focusRemainingSeconds)
            : const Text('مرور'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          // دکمه‌ی تمرکز — فقط وقتی نشست شروع شده و هنوز فعال نیست.
          if (state.focusActive)
            IconButton(
              icon: const Icon(Icons.timer_off_rounded),
              tooltip: 'توقف تمرکز',
              onPressed: controller.stopFocus,
            )
          else if (!state.finished && state.cards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.timer_outlined),
              tooltip: 'حالت تمرکز',
              onPressed: () => _showFocusSheet(context, controller),
            ),
          if (state.canUndo && !state.finished && !typedMode)
            IconButton(
              icon: const Icon(Icons.undo_rounded),
              tooltip: 'بازگشت',
              onPressed: controller.undo,
            ),
        ],
        bottom: state.cards.isNotEmpty && !state.finished
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 4,
                  backgroundColor: context.colors.bg3,
                  valueColor:
                      AlwaysStoppedAnimation(context.colors.accent),
                ),
              )
            : null,
      ),
      body: SafeArea(child: body),
    );
  }

  /// نمایش شیت انتخاب مدت زمان تمرکز.
  void _showFocusSheet(BuildContext context, ReviewController controller) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final c = Theme.of(ctx).extension<AppPalette>()!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('حالت تمرکز 🔥',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 6),
              Text('یه زمان انتخاب کن و بدون حواس‌پرتی مرور کن',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: c.textMuted)),
              const SizedBox(height: 20),
              for (final minutes in [5, 10, 15])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FocusDurationTile(
                    minutes: minutes,
                    onTap: () {
                      controller.startFocus(minutes);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// عنوان تایمر تمرکز در AppBar — «MM:SS» فارسی با آیکون 🔥.
class _FocusTitle extends StatelessWidget {
  const _FocusTitle({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department_rounded,
            color: context.colors.amber, size: 20),
        const SizedBox(width: 6),
        Text('${Fa.digits(m)}:${Fa.digits(s)}',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.colors.amber,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

/// گزینه‌ی مدت زمان تمرکز در شیت.
class _FocusDurationTile extends StatelessWidget {
  const _FocusDurationTile({required this.minutes, required this.onTap});
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: c.amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_rounded, color: c.amber, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '${Fa.digits(minutes)} دقیقه',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary),
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: c.amber),
          ],
        ),
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({required this.state, required this.controller});
  final ReviewState state;
  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    final card = state.current!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${Fa.digits(state.position)} از ${Fa.digits(state.total)}',
              style: TextStyle(
                  fontSize: 13, color: context.colors.textSecondary),
            ),
          ),
          Expanded(
            child: Center(
              child: FlipCard(
                key: ValueKey(card.id ?? state.index),
                showBack: state.showAnswer,
                onTap: controller.flip,
                front: _CardFace(
                  text: card.front,
                  isBack: false,
                ),
                back: _CardFace(
                  text: card.back,
                  isBack: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!state.showAnswer)
            Text('برای دیدن جواب روی کارت بزن',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted))
          else
            _RatingBar(onRate: controller.rate),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// بدنه‌ی مرور در حالت «تایپ جواب».
class _TypedReviewBody extends StatefulWidget {
  const _TypedReviewBody({required this.state, required this.controller});
  final ReviewState state;
  final ReviewController controller;

  @override
  State<_TypedReviewBody> createState() => _TypedReviewBodyState();
}

class _TypedReviewBodyState extends State<_TypedReviewBody> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    if (_c.text.trim().isEmpty) return;
    widget.controller.submitTyped(_c.text);
  }

  void _continue() {
    widget.controller.continueTyped();
    _c.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final card = state.current!;
    final answered = state.showAnswer;
    final last = state.position == state.total;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${Fa.digits(state.position)} از ${Fa.digits(state.total)}',
              style:
                  TextStyle(fontSize: 13, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _CardFace(text: card.front, isBack: false),
                  const SizedBox(height: 20),
                  if (!answered)
                    TextField(
                      controller: _c,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration:
                          const InputDecoration(hintText: 'جوابت رو بنویس…'),
                    )
                  else
                    _TypedResult(
                      back: card.back,
                      correct: state.typedCorrect,
                      typed: state.typedAnswer,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: answered ? _continue : _submit,
              child: Text(answered ? (last ? 'پایان مرور' : 'کارت بعدی') : 'بررسی'),
            ),
          ),
        ],
      ),
    );
  }
}

/// پنل نتیجه‌ی جوابِ تایپ‌شده.
class _TypedResult extends StatelessWidget {
  const _TypedResult(
      {required this.back, required this.correct, required this.typed});
  final String back;
  final bool correct;
  final String typed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = correct ? c.teal : c.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: color, size: 24),
              const SizedBox(width: 8),
              Text(correct ? 'درست بود! 🎉' : 'نادرست',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 16),
          Text('جواب درست',
              style: TextStyle(fontSize: 11, color: c.textMuted)),
          const SizedBox(height: 6),
          MathText(back,
              style: TextStyle(
                  fontSize: 20,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: c.teal)),
          if (!correct && typed != '—') ...[
            const SizedBox(height: 14),
            Text('جواب تو',
                style: TextStyle(fontSize: 11, color: c.textMuted)),
            const SizedBox(height: 4),
            Text(typed,
                style: TextStyle(
                    fontSize: 16,
                    color: c.red,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: c.red)),
          ],
        ],
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.text, required this.isBack});
  final String text;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBack ? context.colors.teal.withValues(alpha: 0.4) : context.colors.border2,
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          if (TtsService.isSpeakable(text))
            Align(
              alignment: Alignment.topLeft,
              child: _SpeakerButton(text: text),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isBack ? 'جواب' : 'سوال',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    color:
                        isBack ? context.colors.teal : context.colors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                MathText(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    color: isBack
                        ? context.colors.teal
                        : context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// دکمه‌ی بلندگو برای تلفظ متن کارت.
class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.volume_up_rounded,
          size: 22, color: context.colors.textMuted),
      tooltip: 'تلفظ',
      visualDensity: VisualDensity.compact,
      onPressed: () => TtsService.instance.speak(text),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.onRate});
  final void Function(Rating) onRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RateButton(
            label: Rating.hard.label,
            color: context.colors.red,
            onTap: () => onRate(Rating.hard),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RateButton(
            label: Rating.good.label,
            color: context.colors.teal,
            onTap: () => onRate(Rating.good),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RateButton(
            label: Rating.easy.label,
            color: context.colors.accent,
            onTap: () => onRate(Rating.easy),
          ),
        ),
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton(
      {required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

class _SummaryView extends ConsumerWidget {
  const _SummaryView({
    required this.hard,
    required this.good,
    required this.easy,
    this.focusEnded = false,
  });
  final int hard;
  final int good;
  final int easy;
  final bool focusEnded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = hard + good + easy;
    final goal = ref.watch(settingsProvider).dailyGoal;
    final todayReviewed = ref.watch(statsProvider).todayReviewed;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(focusEnded ? '🔥' : '🎉', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            focusEnded ? 'زمان تمرکز تمام شد!' : 'آفرین! مرور تمام شد',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text('${Fa.digits(total)} کارت رو مرور کردی',
              style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 24),
          _GoalProgress(done: todayReviewed, goal: goal),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                  child: _SummaryStat(
                      'سخت', Fa.digits(hard), context.colors.red)),
              const SizedBox(width: 10),
              Expanded(
                  child: _SummaryStat(
                      'خوب', Fa.digits(good), context.colors.teal)),
              const SizedBox(width: 10),
              Expanded(
                  child: _SummaryStat(
                      'آسون', Fa.digits(easy), context.colors.accent)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('بازگشت به خانه'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}

/// نوار پیشرفت هدف روزانه در پایان مرور.
class _GoalProgress extends StatelessWidget {
  const _GoalProgress({required this.done, required this.goal});
  final int done;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final reached = goal > 0 && done >= goal;
    final pct = goal == 0 ? 0.0 : (done / goal).clamp(0.0, 1.0);
    final color = reached ? context.colors.teal : context.colors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(reached ? 'به هدف امروز رسیدی 🎯' : 'هدف روزانه',
                style: TextStyle(
                    fontSize: 13, color: context.colors.textSecondary)),
            Text('${Fa.digits(done)} از ${Fa.digits(goal)}',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 10, color: context.colors.bg3),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(height: 10, color: color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✓', style: TextStyle(fontSize: 56, color: context.colors.teal)),
          const SizedBox(height: 16),
          const Text('کارتی برای مرور نیست',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('بعداً که کارت‌ها سررسید بشن اینجا می‌بینی‌شون',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('بازگشت'),
            ),
          ),
        ],
      ),
    );
  }
}
