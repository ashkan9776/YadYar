import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/flashcard.dart';
import '../../providers/providers.dart';

/// شیت پایین‌صفحه برای ساخت یا ویرایش یک کارت.
Future<void> showCardEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  required int deckId,
  FlashCard? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CardEditor(deckId: deckId, existing: existing),
  );
}

class _CardEditor extends ConsumerStatefulWidget {
  const _CardEditor({required this.deckId, this.existing});
  final int deckId;
  final FlashCard? existing;

  @override
  ConsumerState<_CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends ConsumerState<_CardEditor> {
  late final TextEditingController _front =
      TextEditingController(text: widget.existing?.front ?? '');
  late final TextEditingController _back =
      TextEditingController(text: widget.existing?.back ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(cardRepositoryProvider);
    final front = _front.text.trim();
    final back = _back.text.trim();

    if (widget.existing == null) {
      await repo.add(FlashCard(
        deckId: widget.deckId,
        front: front,
        back: back,
        nextReview: DateTime.now(),
      ));
    } else {
      await repo.update(widget.existing!.copyWith(front: front, back: back));
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    // SafeArea فاصله‌ی نوار ناوبری گوشی را اضافه می‌کند (top:false چون شیت پایین است)
    // و viewInsets ارتفاع کیبورد را؛ پس دکمه‌ها هیچ‌وقت زیر نوار ناوبری نمی‌روند.
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'ویرایش کارت' : 'کارت جدید',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('سوال (روی کارت)',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _front,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'مثلاً: مشتق sin(x)؟'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'سوال را وارد کن' : null,
            ),
            const SizedBox(height: 14),
            Text('جواب (پشت کارت)',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _back,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'مثلاً: cos(x)'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'جواب را وارد کن' : null,
            ),
            const SizedBox(height: 8),
            Text(r'فرمول ریاضی را بین دو $ بنویس، مثل $x^2$',
                style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'ذخیره تغییرات' : 'افزودن کارت'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
