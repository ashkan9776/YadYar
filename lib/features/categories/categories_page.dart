import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/freemium_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/category_icons.dart';
import '../../data/models/category.dart';
import '../../features/premium/premium_dialog.dart';
import '../../providers/providers.dart';

/// صفحه‌ی لیست دسته‌بندی‌ها — سطح اول سلسله‌مراتب.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesStreamProvider);
    final books = ref.watch(booksStreamProvider).value ?? const [];
    final catDueCounts = ref.watch(categoryDueCountsProvider);
    final catCardCounts = ref.watch(categoryCardCountsProvider);
    final isPro = ref.watch(isProProvider);
    final categoryCount = ref.watch(categoryCountProvider);

    // شمارش تعداد کتاب‌ها به تفکیک دسته.
    final bookCountByCat = <int, int>{};
    for (final b in books) {
      bookCountByCat[b.categoryId] = (bookCountByCat[b.categoryId] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('دسته‌بندی‌ها')),
      body: SafeArea(
        child: catsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('خطا: $e')),
          data: (cats) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              for (final cat in cats)
                _CategoryCard(
                  category: cat,
                  bookCount: bookCountByCat[cat.id] ?? 0,
                  cardCount: catCardCounts[cat.id] ?? 0,
                  dueCount: catDueCounts[cat.id] ?? 0,
                ),
              const SizedBox(height: 4),
              _NewItemTile(
                label: '+ دسته جدید',
                usageLabel: FreemiumLimits.usageLabel(
                    categoryCount, FreemiumLimits.maxCategories, isPro),
                onTap: () {
                  if (!FreemiumLimits.canCreateCategory(
                      categoryCount, isPro)) {
                    showPremiumDialog(context, ref,
                        reason: FreemiumLimits.limitMessage('category'));
                  } else {
                    context.push('/category-new');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.bookCount,
    required this.cardCount,
    required this.dueCount,
  });
  final Category category;
  final int bookCount;
  final int cardCount;
  final int dueCount;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorHex);
    final icon = CategoryIcons.iconAt(category.iconIndex);

    final subtitle = cardCount == 0
        ? (bookCount == 0 ? 'خالی' : '$bookCount کتاب')
        : dueCount > 0
            ? '$bookCount کتاب — $dueCount کارت امروز'
            : '$bookCount کتاب — تمام شد ✓';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/category/${category.id}'),
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title,
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
              if (dueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('$dueCount',
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

/// کاشی «افزودن مورد جدید» با حاشیه‌ی خط‌چین.
class _NewItemTile extends StatelessWidget {
  const _NewItemTile({required this.label, required this.onTap, this.usageLabel});
  final String label;
  final VoidCallback onTap;
  final String? usageLabel;

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
          child: usageLabel != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(usageLabel!,
                        style: TextStyle(
                            fontSize: 12, color: context.colors.textMuted)),
                  ],
                )
              : Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary)),
        ),
      ),
    );
  }
}
