import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// کانتینر شیشه‌مورفیسمی — پس‌زمینه نیمه‌شفاف با بلور پس‌زمینه‌ی پشتش.
/// برای هدرها، نوار ناوبری پایین و overlayها استفاده می‌شه.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.8,
    this.radius = 0,
    this.border,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double radius;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          margin: margin,
          padding: padding,
          decoration: BoxDecoration(
            color: c.bg2.withValues(alpha: opacity),
            border: border ?? Border.all(color: c.border),
          ),
          child: child,
        ),
      ),
    );
  }
}
