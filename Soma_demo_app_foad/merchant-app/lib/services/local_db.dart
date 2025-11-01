import 'package:shared_preferences/shared_preferences.dart';

/// LocalDB — نسخهٔ ساده برای دمو مرچنت
/// - نگه‌داری موجودی هر کیف (wallet) در SharedPreferences
/// - متدهای دریافت مبلغ (receiveAmount) و گرفتن موجودی (getBalance)
class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  SharedPreferences? _sp;

  /// فراخوانی در اولین استفاده به صورت Lazy
  Future<void> _ensureInit() async {
    _sp ??= await SharedPreferences.getInstance();
  }

  String _key(String wallet) => 'wallet_balance_$wallet';

  /// مقدار پیش‌فرض دمو اگر قبلاً چیزی نبود
  static const int _defaultBalance = 0;

  /// دریافت موجودی فعلی یک کیف
  Future<int> getBalance(String wallet) async {
    await _ensureInit();
    return _sp!.getInt(_key(wallet)) ?? _defaultBalance;
  }

  /// ست کردن موجودی
  Future<bool> _setBalance(String wallet, int value) async {
    await _ensureInit();
    return _sp!.setInt(_key(wallet), value);
  }

  /// ✅ موردی که لاگ خطا می‌گرفت: این متد باید دقیقاً با همین نام وجود داشته باشد.
  /// افزایش موجودی (مرچنت پول دریافت می‌کند)
  Future<bool> receiveAmount(int amount, String wallet) async {
    await _ensureInit();
    final current = await getBalance(wallet);
    final next = current + (amount.abs());
    return _setBalance(wallet, next);
  }

  /// متدهای کمکی برای دمو/دیباگ
  Future<bool> setExactBalance(String wallet, int value) => _setBalance(wallet, value);

  Future<bool> resetAll({String wallet = 'main'}) async {
    await _ensureInit();
    return _sp!.remove(_key(wallet));
  }
}
