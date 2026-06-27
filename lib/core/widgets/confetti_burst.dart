import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// انفجار کاغذرنگی یک‌بارمصرف برای جشن گرفتن (بدون وابستگی خارجی).
/// به‌صورت یک لایه‌ی شفاف روی محتوا قرار می‌گیرد و یک‌بار پخش می‌شود.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particleCount = 90,
    this.colors,
    this.haptic = true,
  });

  final int particleCount;
  final List<Color>? colors;
  final bool haptic;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final List<_Particle> _particles;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    if (widget.haptic) HapticFeedback.heavyImpact();
    const fallback = [
      Color(0xFF7F77DD),
      Color(0xFF5DCAA5),
      Color(0xFFEF9F27),
      Color(0xFFE24B4A),
      Color(0xFFAFA9EC),
      Color(0xFF4A9BE2),
    ];
    final colors = widget.colors ?? fallback;
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        x: _rnd.nextDouble(),
        size: 6 + _rnd.nextDouble() * 9,
        color: colors[_rnd.nextInt(colors.length)],
        drift: (_rnd.nextDouble() - 0.5) * 0.35,
        delay: _rnd.nextDouble() * 0.25,
        rotation: _rnd.nextDouble() * math.pi * 2,
        rotationSpeed: (_rnd.nextDouble() - 0.5) * 9,
        fallScale: 0.85 + _rnd.nextDouble() * 0.5,
      );
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c.value),
        ),
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.size,
    required this.color,
    required this.drift,
    required this.delay,
    required this.rotation,
    required this.rotationSpeed,
    required this.fallScale,
  });

  final double x; // موقعیت افقی اولیه (۰..۱)
  final double size;
  final Color color;
  final double drift; // جابه‌جایی افقی حین سقوط
  final double delay; // تأخیر شروع (۰..۱)
  final double rotation;
  final double rotationSpeed;
  final double fallScale;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final prog = (local * p.fallScale).clamp(0.0, 1.0);
      final dy = prog * (size.height + 40) - 20;
      final dx = (p.x + p.drift * prog) * size.width;
      final opacity = (1.0 - local).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation + p.rotationSpeed * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
