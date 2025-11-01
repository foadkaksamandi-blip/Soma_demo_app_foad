import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  static const _kMain = 'wallet_main';
  static const _kSubsidy = 'wallet_subsidy';
  static const _kEmergency = 'wallet_emergency';
  static const _kCrypto = 'wallet_crypto';
  static const _kLastTxId = 'last_tx_id';

  Future<SharedPreferences> get _sp async => SharedPreferences.getInstance();

  Future<void> ensureDefaults() async {
    final sp = await _sp;
    if (!sp.containsKey(_kMain)) {
      await sp.setInt(_kMain, 100000);
      await sp.setInt(_kSubsidy, 50000);
      await sp.setInt(_kEmergency, 20000);
      await sp.setInt(_kCrypto, 300000);
      await sp.setInt(_kLastTxId, 100000 + Random().nextInt(900000));
    }
  }

  Future<int> balance(String wallet) async {
    final sp = await _sp;
    switch (wallet) {
      case 'main':
        return sp.getInt(_kMain) ?? 0;
      case 'subsidy':
        return sp.getInt(_kSubsidy) ?? 0;
      case 'emergency':
        return sp.getInt(_kEmergency) ?? 0;
      case 'crypto':
        return sp.getInt(_kCrypto) ?? 0;
      default:
        return 0;
    }
  }

  Future<bool> _setBalance(String wallet, int v) async {
    final sp = await _sp;
    switch (wallet) {
      case 'main':
        return sp.setInt(_kMain, v);
      case 'subsidy':
        return sp.setInt(_kSubsidy, v);
      case 'emergency':
        return sp.setInt(_kEmergency, v);
      case 'crypto':
        return sp.setInt(_kCrypto, v);
      default:
        return false;
    }
  }

  /// کاهش موجودی (خرید)
  Future<bool> spend_amount(int amount, String wallet) async {
    await ensureDefaults();
    final cur = await balance(wallet);
    if (amount <= 0 || cur < amount) return false;
    return _setBalance(wallet, cur - amount);
  }

  /// افزایش موجودی (دریافت)
  Future<bool> receive_amount(int amount, String wallet) async {
    await ensureDefaults();
    final cur = await balance(wallet);
    if (amount <= 0) return false;
    return _setBalance(wallet, cur + amount);
  }

  Future<String> newTxId() async {
    final sp = await _sp;
    final next = (sp.getInt(_kLastTxId) ?? 0) + 1;
    await sp.setInt(_kLastTxId, next);
    return next.toString();
  }
}
