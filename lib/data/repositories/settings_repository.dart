import 'package:sembast/sembast.dart';

import '../db/app_database.dart';
import '../models/app_settings.dart';

/// خواندن و نوشتن تنظیمات کاربر (یک رکورد در استور settings).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;
  static const _key = 'app';

  /// خواندن تنظیمات؛ اگر چیزی ذخیره نشده باشد، پیش‌فرض‌ها برمی‌گردند.
  Future<AppSettings> load() async {
    final rec = await AppDatabase.settings.record(_key).get(_db.db);
    return rec == null ? AppSettings.defaults : AppSettings.fromMap(rec);
  }

  Future<void> save(AppSettings settings) async {
    await AppDatabase.settings.record(_key).put(_db.db, settings.toMap());
  }

  /// جریان زنده‌ی تنظیمات برای واکنش لحظه‌ای رابط کاربری.
  Stream<AppSettings> watch() {
    return AppDatabase.settings.record(_key).onSnapshot(_db.db).map(
          (snap) =>
              snap == null ? AppSettings.defaults : AppSettings.fromMap(snap.value),
        );
  }
}
