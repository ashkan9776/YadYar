import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/deck.dart';
import '../../providers/providers.dart';

/// ساخت یا ویرایش یک دک (نام، توضیح، رنگ).
class DeckEditPage extends ConsumerStatefulWidget {
  const DeckEditPage({super.key, this.deckId});
  final int? deckId;

  @override
  ConsumerState<DeckEditPage> createState() => _DeckEditPageState();
}

class _DeckEditPageState extends ConsumerState<DeckEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  int _colorHex = AppColors.deckPalette.first;
  Deck? _existing;
  bool _loaded = false;

  bool get _isEdit => widget.deckId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    final deck = await ref.read(deckRepositoryProvider).getById(widget.deckId!);
    if (deck != null && mounted) {
      setState(() {
        _existing = deck;
        _title.text = deck.title;
        _desc.text = deck.description ?? '';
        _colorHex = deck.colorHex;
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
    final repo = ref.read(deckRepositoryProvider);
    final title = _title.text.trim();
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();

    if (_isEdit && _existing != null) {
      await repo.update(_existing!
          .copyWith(title: title, description: desc, colorHex: _colorHex));
    } else {
      await repo.add(Deck(
        title: title,
        description: desc,
        colorHex: _colorHex,
        createdAt: DateTime.now(),
        isBuiltIn: false,
      ));
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && !_loaded) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'ویرایش دک' : 'دک جدید')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('نام دک',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _title,
                decoration:
                    const InputDecoration(hintText: 'مثلاً: زیست‌شناسی فصل ۳'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'نام دک را وارد کن'
                    : null,
              ),
              const SizedBox(height: 16),
              Text('توضیح (اختیاری)',
                  style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _desc,
                decoration:
                    const InputDecoration(hintText: 'یک توضیح کوتاه'),
              ),
              const SizedBox(height: 20),
              Text('رنگ دک',
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
                child: Text(_isEdit ? 'ذخیره' : 'ساخت دک'),
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
