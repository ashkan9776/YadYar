import 'package:flutter/material.dart';

/// نشان کوچک پرو (👑) برای نمایش در AppBar.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text('👑', style: TextStyle(fontSize: 14)),
    );
  }
}
