import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast_io.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/persian.dart';
import '../../core/theme/app_colors.dart';
import '../../data/db/app_database.dart';
import '../../data/services/backup_service.dart';
import '../../providers/providers.dart';

/// صفحه‌ی مدیریت داده — پشتیبان‌گیری، بازیابی و حذف داده‌ها.
class DataManagementPage extends ConsumerStatefulWidget {
  const DataManagementPage({super.key});

  @override
  ConsumerState<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends ConsumerState<DataManagementPage> {
  bool _exporting = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت داده')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _SectionLabel('پشتیبان‌گیری'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خروجی JSON',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'فایل شامل همه‌ی دک‌ها، کارت‌ها، مرورها و تنظیمات. '
                    'از طریق اشتراک‌گذاری به هر جا که بخوای بفرستش.',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exporting
                          ? null
                          : () => _handleExport(context),
                      icon: _exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        _exporting ? 'در حال ساخت...' : 'ایجاد و اشتراک‌گذاری',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('بازیابی'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'وارد کردن فایل',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'داده‌های فعلی با فایل پشتیبان جایگزین می‌شوند. '
                    'قبل از وارد کردن، حتماً یک پشتیبان بگیر!',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _importing
                          ? null
                          : () => _handleImport(context),
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.restore_rounded, size: 20),
                      label: Text(
                        _importing
                            ? 'در حال بارگذاری...'
                            : 'انتخاب فایل و بازیابی',
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.teal600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _SectionLabel('خطر'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حذف محتوای مطالعه',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: c.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'دسته‌بندی‌ها، کتاب‌ها، دک‌ها، کارت‌ها و تاریخچه‌ی مرور حذف می‌شوند. '
                    'تنظیمات برنامه باقی می‌مانند. این عمل قابل بازگشت نیست!',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReset(context),
                      icon: const Icon(Icons.delete_forever_rounded, size: 20),
                      label: Text(
                        'حذف محتوای مطالعه',
                        style: TextStyle(fontSize: 14, color: c.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.red,
                        side: BorderSide(color: c.red.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ساخت عکس‌فوری و اشتراک‌گذاری فایل JSON.
  Future<void> _handleExport(BuildContext context) async {
    setState(() => _exporting = true);
    try {
      final db = ref.read(databaseProvider);
      final service = BackupService(db);
      final snapshot = await service.exportSnapshot();
      final filePath = await service.saveToFile(snapshot);

      // فرمت نام فایل: yadyar_backup_تاریخ.json
      final dateStr = Fa.fullDate(DateTime.now()).replaceAll(' ', '_');
      final xFile = XFile(filePath, name: 'yadyar_backup_$dateStr.json');

      // ignore: deprecated_member_use
      await Share.shareXFiles([
        xFile,
      ], text: 'پشتیبان یادیار — ${Fa.fullDate(DateTime.now())}');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فایل پشتیبان ساخته شد ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ساخت پشتیبان: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  /// انتخاب فایل JSON و بازیابی داده‌ها (با تأیید کاربر).
  Future<void> _handleImport(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('بازیابی از فایل'),
        content: const Text('داده‌های فعلی جایگزین می‌شوند. آیا مطمئنی؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('بازیابی'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);
    try {
      // انتخاب فایل با فیلتر JSON.
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) {
        if (mounted) setState(() => _importing = false);
        return;
      }

      final snapshot = await BackupService.loadFromFile(
        result.files.single.path!,
      );

      final db = ref.read(databaseProvider);
      final service = BackupService(db);
      await service.importSnapshot(snapshot);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بازیابی با موفقیت انجام شد ✅'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // بازگشت به خانه برای بارگذاری مجدد داده‌ها.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در بازیابی: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  /// حذف همه‌ی داده‌ها (با تأیید).
  Future<void> _handleReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ حذف محتوای مطالعه'),
        content: const Text(
          'دسته‌بندی‌ها، کتاب‌ها، دک‌ها، کارت‌ها و تاریخچه‌ی مرور برای همیشه حذف می‌شوند. '
          'تنظیمات برنامه باقی می‌مانند. این عمل قابل بازگشت نیست!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.colors.red),
            child: const Text('حذف محتوا'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final db = ref.read(databaseProvider);
    await db.db.transaction((txn) async {
      await AppDatabase.categories.delete(txn);
      await AppDatabase.books.delete(txn);
      await AppDatabase.decks.delete(txn);
      await AppDatabase.cards.delete(txn);
      await AppDatabase.reviews.delete(txn);
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('محتوای مطالعه حذف شد'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: child,
    );
  }
}
