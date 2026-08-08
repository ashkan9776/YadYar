import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// لایه‌ی دسترسی به دیتابیس محلی (سِم‌بَست) — کاملاً آفلاین، بدون codegen.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const _dbFileName = 'yadyar.db';

  // استورها (معادل جدول‌ها) با کلید عددی خودافزا.
  static final categories = intMapStoreFactory.store('categories');
  static final books = intMapStoreFactory.store('books');
  static final decks = intMapStoreFactory.store('decks');
  static final cards = intMapStoreFactory.store('cards');
  static final reviews = intMapStoreFactory.store('reviews');

  // استور تنظیمات: تک‌رکورد با کلید رشته‌ای.
  static final settings = stringMapStoreFactory.store('settings');

  /// باز کردن دیتابیس روی دیسک دستگاه.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbFileName);
    final db = await databaseFactoryIo.openDatabase(path);
    return AppDatabase._(db);
  }
}
