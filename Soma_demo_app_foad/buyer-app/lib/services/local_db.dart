import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// پایگاه دادهٔ محلی ساده برای دمو
/// کلیدها: wallet_main, wallet_subsidy, wallet_emergency, wallet_crypto
class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  SharedPreferences? _sp;

  Future<void> _ensure() async {
    _sp ??= await SharedPreferences.getInstance();
    // مقادیر اولیه اگر وجود ندارند
    _sp!.setInt('wallet_main', _sp!.getInt('wallet_main') ?? 100000);
    _sp!.setInt('wallet_subsidy', _sp!.getInt('wallet_subsidy') ?? 50000);
    _sp!.setInt('wallet_emergency', _sp!.getInt('wallet_emergency') ?? 20000);
    _sp!.setInt('wallet_crypto', _sp!.getInt('wallet_crypto') ?? 300000);
  }

  int _getBalance(String wallet) {
    switch (wallet) {
      case 'subsidy':
        return _sp!.getInt('wallet_subsidy') ?? 0;
      case 'emergency':
        return _sp!.getInt('wallet_emergency') ?? 0;
      case 'crypto':
        return _sp!.getInt('wallet_crypto') ?? 0;
      case 'main':
      default:
        return _sp!.getInt('wallet_main') ?? 0;
    }
  }

  Future<bool> spendAmount(int amount, String wallet) async {
    await _ensure();
    if (amount <= 0) return false;

    final current = _getBalance(wallet);
    if (current < amount) return false;

    final newVal = current - amount;
    switch (wallet) {
      case 'subsidy':
        await _sp!.setInt('wallet_subsidy', newVal);
        break;
      case 'emergency':
        await _sp!.setInt('wallet_emergency', newVal);
        break;
      case 'crypto':
        await _sp!.setInt('wallet_crypto', newVal);
        break;
      case 'main':
      default:
        await _sp!.setInt('wallet_main', newVal);
        break;
    }
    return true;
  }

  Future<String> newTxId() async {
    await _ensure();
    final rnd = Random();
    final id =
        '${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}-${rnd.nextInt(1 << 20).toRadixString(16)}';
    return id;
    // (در دمو نیازی به ذخیره تاریخچه نیست؛ صرفاً شناسه برمی‌گردد)
  }
}
