import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:yadyar/core/widgets/confetti_burst.dart';

/// نام فونت فارسی — مطابق تعریف pubspec.yaml.
const _kFontFamily = 'Vazirmatn';

/// لایه‌ی شفاف روی رابط کاربری برای نمایش جشن‌های موقتی
/// (لول‌آپ و آنلاک دستاورد). خودکار محو می‌شود.
class CelebrationOverlay {
  CelebrationOverlay._();

  static OverlayEntry? _active;

  /// نشان دادن جشن لول‌آپ با کانفتی و پیام سطح جدید.
  /// اگر همزمان اورلی دیگر فعال باشد، نادیده گرفته می‌شود.
  static void showLevelUp(BuildContext context, int newLevel) {
    if (_active != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _active = OverlayEntry(
      builder: (_) => _LevelUpWidget(
        level: newLevel,
        onDone: _dismiss,
      ),
    );
    overlay.insert(_active!);
  }

  /// نشان دادن جشن آنلاک دستاورد با کانفتی و پیام عنوان.
  /// اگر همزمان اورلی دیگر فعال باشد، نادیده گرفته می‌شود.
  static void showAchievement(
      BuildContext context, String title, String description) {
    if (_active != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _active = OverlayEntry(
      builder: (_) => _AchievementWidget(
        title: title,
        description: description,
        onDone: _dismiss,
      ),
    );
    overlay.insert(_active!);
  }

  static void _dismiss() {
    _active?.remove();
    _active = null;
  }
}

/// ویجت جشن لول‌آپ — نوار بنفش با انیمیشن ورود + کانفتی.
class _LevelUpWidget extends StatefulWidget {
  const _LevelUpWidget({required this.level, required this.onDone});
  final int level;
  final VoidCallback onDone;

  @override
  State<_LevelUpWidget> createState() => _LevelUpWidgetState();
}

class _LevelUpWidgetState extends State<_LevelUpWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _c.forward();
      _timer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) {
          widget.onDone();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ConfettiBurst(),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _c,
                curve: Curves.easeOutBack,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _c,
                  curve: Curves.easeIn,
                ),
                child: _LevelUpCard(level: widget.level),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelUpCard extends StatelessWidget {
  const _LevelUpCard({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7F77DD), Color(0xFF5D4FC4)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7F77DD).withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.military_tech_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('لول‌آپ! 🎉',
                    style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  'به سطح ${_faDigits(level)} رسیدی',
                  style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ویجت جشن آنلاک دستاورد — کارت طلایی با انیمیشن ورود + کانفتی.
class _AchievementWidget extends StatefulWidget {
  const _AchievementWidget({
    required this.title,
    required this.description,
    required this.onDone,
  });
  final String title;
  final String description;
  final VoidCallback onDone;

  @override
  State<_AchievementWidget> createState() => _AchievementWidgetState();
}

class _AchievementWidgetState extends State<_AchievementWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _c.forward();
      _timer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) {
          widget.onDone();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ConfettiBurst(
          colors: [
            Color(0xFFEF9F27),
            Color(0xFFF5D060),
            Color(0xFF7F77DD),
            Color(0xFFE24B4A),
            Color(0xFFAFA9EC),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _c,
                curve: Curves.easeOutBack,
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _c,
                  curve: Curves.easeIn,
                ),
                child: _AchievementCard(
                  title: widget.title,
                  description: widget.description,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF9F27), Color(0xFFD4880C)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF9F27).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('دستاورد جدید! 🏆',
                    style: TextStyle(
                        fontFamily: _kFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: TextStyle(
                      fontFamily: _kFontFamily,
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// تبدیل ارقام لاتین به فارسی (بدون وابستگی به Fa برای انتخا‌پذیری).
String _faDigits(Object input) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final s = input.toString();
  final buffer = StringBuffer();
  for (final ch in s.runes) {
    if (ch >= 48 && ch <= 57) {
      buffer.write(fa[ch - 48]);
    } else {
      buffer.writeCharCode(ch);
    }
  }
  return buffer.toString();
}
