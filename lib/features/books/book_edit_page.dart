import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/book.dart';
import '../../providers/providers.dart';

/// ساخت یا ویرایش یک کتاب (نام، توضیح، رنگ).
class BookEditPage extends ConsumerStatefulWidget {
  const BookEditPage({super.key, this.bookId, this.categoryId});
  final int? bookId;
  final int? categoryId;

  @override
  ConsumerState<BookEditPage> createState() => _BookEditPageState();
}

class _BookEditPageState extends ConsumerState<BookEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _colorHex = AppColors.deckPalette.first;
  Book? _existing;
  bool _loaded = false;

  bool get _isEdit => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    final book =
        await ref.read(bookRepositoryProvider).getById(widget.bookId!);
    if (book != null && mounted) {
      setState(() {
        _existing = book;
        _title.text = book.title;
        _desc.text = book.description ?? '';
        _colorHex = book.colorHex;
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
    final repo = ref.read(bookRepositoryProvider);
    final title = _title.text.trim();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();

    if (_isEdit && _existing != null) {
      await repo.update(
          _existing!.copyWith(title: title, description: desc, colorHex: _colorHex));
    } else {
      await repo.add(Book(
        categoryId: widget.categoryId!,
        title: title,
        description: desc,
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
      appBar: AppBar(title: Text(_isEdit ? 'ویرایش کتاب' : 'کتاب جدید')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('نام کتاب',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    hintText: 'مثلاً: Complete IELTS Bands 5-6.5'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نام کتاب را وارد کن'
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
                child: Text(_isEdit ? 'ذخیره' : 'ساخت کتاب'),
              ),
            ],
          ),
        ),
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
