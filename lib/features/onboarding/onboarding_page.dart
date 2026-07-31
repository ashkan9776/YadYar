import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

/// صفحه‌ی آنبوردینگ — معرفی کوتاه اپ در ۳ اسلاید.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _current = 0;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.auto_stories_rounded,
      title: 'یادیار',
      description:
          'با تکرار فاصله‌دار، مطالب رو طوری یاد بگیر که تو ذهنت بمونه. '
          'هر چیز یاد گرفتی رو به‌موقع مرور می‌کنیم.',
      color: null, // از accent استفاده می‌شه
    ),
    _Slide(
      icon: Icons.psychology_rounded,
      title: 'هوشمند',
      description:
          'الگوریتم SM-2 نقاط ضعف تو رو پیدا می‌کنه و کارت‌های سخت‌تر رو '
          'بیشتر نشون می‌ده. هرچه بیشتر تمرین کنی، هوشمندتر می‌شه.',
      color: null,
    ),
    _Slide(
      icon: Icons.rocket_launch_rounded,
      title: 'شروع کن',
      description:
          'اولین دک خودت رو بساز، کارت‌ها رو اضافه کن و سفر یادگیریت رو '
          'امروز آغاز کن!',
      color: null,
    ),
  ];

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    await ref.read(settingsRepositoryProvider).save(
          settings.copyWith(onboardingDone: true),
        );
    if (mounted) context.go('/');
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // دکمه‌ی رد کردن
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _finish,
                  child: Text('رد کردن',
                      style: TextStyle(color: c.textMuted, fontSize: 14)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _SlideView(
                  slide: _slides[i],
                  color: c.accent,
                  glow: c.accentGlow,
                ),
              ),
            ),
            // Indicator و دکمه
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? c.accent : c.bg3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _current == _slides.length - 1
                            ? 'شروع یادگیری 🚀'
                            : 'بعدی',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? color;
}

class _SlideView extends StatelessWidget {
  const _SlideView({
    required this.slide,
    required this.color,
    required this.glow,
  });

  final _Slide slide;
  final Color color;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // آیکون با glow
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.25), glow],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(slide.icon, size: 56, color: color),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.8,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
