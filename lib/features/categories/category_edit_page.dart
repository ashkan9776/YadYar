import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/category_icons.dart';
import '../../data/models/category.dart';
import '../../providers/providers.dart';

/// ساخت یا ویرایش یک دسته‌بندی (نام، توضیح، آیکون، رنگ).
class CategoryEditPage extends ConsumerStatefulWidget {
  const CategoryEditPage({super.key, this.categoryId});
  final int? categoryId;

  @override
  ConsumerState<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends ConsumerState<CategoryEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _iconIndex = 6; // General به‌صورت پیش‌فرض
  int _colorHex = AppColors.deckPalette.first;
  Category? _existing;
  bool _loaded = false;

  bool get _isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    final cat =
        await ref.read(categoryRepositoryProvider).getById(widget.categoryId!);
    if (cat != null && mounted) {
      setState(() {
        _existing = cat;
        _title.text = cat.title;
        _desc.text = cat.description ?? '';
        _iconIndex = cat.iconIndex;
        _colorHex = cat.colorHex;
        _loaded = true;
      });
    } else {
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(categoryRepositoryProvider);
    final title = _title.text.trim();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();

    if (_isEdit && _existing != null) {
      await repo.update(_existing!.copyWith(
          title: title, description: desc, iconIndex: _iconIndex, colorHex: _colorHex));
    } else {
      await repo.add(Category(
        title: title,
        description: desc,
        iconIndex: _iconIndex,
        colorHex: _colorHex,
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && !_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'ویرایش دسته' : 'دسته جدید')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('نام دسته',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    hintText: 'مثلاً: Speaking، Reading، گرامر'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نام دسته را وارد کن'
                    : null,
              ),
              const SizedBox(height: 16),
              Text('توضیح (اختیاری)',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(hintText: 'یک توضیح کوتاه'),
              ),
              const SizedBox(height: 20),
              Text('آیکون',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < CategoryIcons.icons.length; i++)
                    _IconDot(
                      icon: CategoryIcons.icons[i],
                      color: Color(_colorHex),
                      selected: i == _iconIndex,
                      onTap: () => setState(() => _iconIndex = i),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('رنگ',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final hex in AppColors.deckPalette)
                    _ColorDot(
                      color: Color(hex),
                      selected: hex == _colorHex,
                      onTap: () => setState(() => _colorHex = hex),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: Text(_isEdit ? 'ذخیره' : 'ساخت دسته'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconDot extends StatelessWidget {
  const _IconDot({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.25 : 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
              : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
