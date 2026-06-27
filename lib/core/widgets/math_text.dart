import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// متنی که بخش‌های بین `$...$` را به‌صورت فرمول ریاضی (LaTeX) رندر می‌کند و
/// بقیه را متن معمولی. اگر `$` نداشته باشد، دقیقاً مثل یک Text رفتار می‌کند.
///
/// مثال: `مساحت دایره $\pi r^2$ است`.
class MathText extends StatelessWidget {
  const MathText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final resolved = style ?? DefaultTextStyle.of(context).style;

    if (!text.contains(r'$')) {
      return Text(text, style: resolved, textAlign: textAlign);
    }

    final parts = text.split(r'$');
    final children = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (i.isOdd) {
        // بخش بین دو $ → فرمول.
        children.add(Math.tex(
          p,
          textStyle: resolved,
          mathStyle: MathStyle.text,
          onErrorFallback: (_) => Text('\$$p\$', style: resolved),
        ));
      } else if (p.isNotEmpty) {
        children.add(Text(p, style: resolved));
      }
    }

    return Wrap(
      alignment: textAlign == TextAlign.center
          ? WrapAlignment.center
          : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
