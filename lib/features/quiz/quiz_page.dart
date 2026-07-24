import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../core/tts.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/math_text.dart';
import '../../domain/quiz.dart';
import 'quiz_controller.dart';

/// صفحه‌ی آزمون چندگزینه‌ای.
class QuizPage extends ConsumerWidget {
  const QuizPage({super.key, required this.deckId});
  final int deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider(deckId));
    final controller = ref.read(quizControllerProvider(deckId).notifier);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.isEmpty) {
      body = const _EmptyView();
    } else if (state.finished) {
      body = _ResultView(
        correct: state.correct,
        total: state.total,
        onRetry: controller.restart,
      );
    } else {
      body = _QuestionBody(state: state, controller: controller);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('آزمون'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        bottom: !state.loading && !state.isEmpty && !state.finished
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 4,
                  backgroundColor: context.colors.bg3,
                  valueColor: AlwaysStoppedAnimation(context.colors.accent),
                ),
              )
            : null,
      ),
      body: SafeArea(child: body),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  const _QuestionBody({required this.state, required this.controller});
  final QuizState state;
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final q = state.current!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${Fa.digits(state.position)} از ${Fa.digits(state.total)}',
              style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          _PromptCard(text: q.prompt),
          const SizedBox(height: 20),
          for (var i = 0; i < q.options.length; i++) ...[
            _OptionTile(
              text: q.options[i],
              state: _optionState(i, q),
              onTap: state.answered ? null : () => controller.select(i),
            ),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          if (state.answered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.next,
                child: Text(
                    state.position == state.total ? 'دیدن نتیجه' : 'سوال بعدی'),
              ),
            ),
        ],
      ),
    );
  }

  _OptState _optionState(int i, QuizQuestion q) {
    if (!state.answered) return _OptState.idle;
    if (i == q.correctIndex) return _OptState.correct;
    if (i == state.selectedIndex) return _OptState.wrong;
    return _OptState.dimmed;
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border2, width: 1.5),
      ),
      child: Stack(
        children: [
          if (TtsService.isSpeakable(text))
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.volume_up_rounded,
                    size: 20, color: context.colors.textMuted),
                tooltip: 'تلفظ',
                visualDensity: VisualDensity.compact,
                onPressed: () => TtsService.instance.speak(text),
              ),
            ),
          Center(
            child: MathText(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _OptState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.text, required this.state, required this.onTap});
  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    late Color bg;
    late Color border;
    late Color fg;
    IconData? icon;
    switch (state) {
      case _OptState.idle:
        bg = c.bg2;
        border = c.border;
        fg = c.textPrimary;
      case _OptState.correct:
        bg = c.teal.withValues(alpha: 0.15);
        border = c.teal;
        fg = c.teal;
        icon = Icons.check_circle_rounded;
      case _OptState.wrong:
        bg = c.red.withValues(alpha: 0.15);
        border = c.red;
        fg = c.red;
        icon = Icons.cancel_rounded;
      case _OptState.dimmed:
        bg = c.bg2;
        border = c.border;
        fg = c.textMuted;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: MathText(text,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500, color: fg)),
            ),
            if (icon != null) Icon(icon, color: fg, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView(
      {required this.correct, required this.total, required this.onRetry});
  final int correct;
  final int total;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (correct / total * 100).round();
    final passed = pct >= 70;
    final color = passed ? context.colors.teal : context.colors.accent;
    final emoji = pct >= 90
        ? '🏆'
        : pct >= 70
            ? '🎉'
            : pct >= 40
                ? '💪'
                : '📚';
    final message = pct >= 90
        ? 'عالی بود! تسلط کامل'
        : pct >= 70
            ? 'آفرین! نتیجه‌ی خوبی گرفتی'
            : pct >= 40
                ? 'بد نبود، بازم تمرین کن'
                : 'نیاز به مرور بیشتری داری';

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text('${Fa.digits(pct)}٪',
                  style: TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 4),
              Text('${Fa.digits(correct)} از ${Fa.digits(total)} درست',
                  style: TextStyle(
                      fontSize: 15, color: context.colors.textSecondary)),
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(fontSize: 14, color: context.colors.textMuted)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('آزمون دوباره'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('بازگشت'),
                ),
              ),
            ],
          ),
        ),
        if (passed) const Positioned.fill(child: ConfettiBurst()),
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
          Icon(Icons.quiz_outlined, size: 56, color: context.colors.textMuted),
          const SizedBox(height: 16),
          const Text('برای آزمون کارت کافی نیست',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('حداقل ۲ کارت لازمه تا بشه آزمون چندگزینه‌ای ساخت.',
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
