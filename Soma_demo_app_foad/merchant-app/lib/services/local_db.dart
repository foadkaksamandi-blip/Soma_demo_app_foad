import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  static const _kMerchantBalance = 'merchant_balance';
  static const _kLastTxId = 'merchant_last_tx_id';

  Future<SharedPreferences> get _sp async => SharedPreferences.getInstance();

  Future<void> ensureDefaults() async {
    final sp = await _sp;
    if (!sp.containsKey(_kMerchantBalance)) {
      await sp.setInt(_kMerchantBalance, 0);
      await sp.setInt(_kLastTxId, 500000 + Random().nextInt(900000));
    }
  }

  Future<int> balance() async {
    final sp = await _sp;
    return sp.getInt(_kMerchantBalance) ?? 0;
  }

  Future<bool> receive_amount(int amount) async {
    await ensureDefaults();
    if (amount <= 0) return false;
    final sp = await _sp;
    final cur = sp.getInt(_kMerchantBalance) ?? 0;
    return sp.setInt(_kMerchantBalance, cur + amount);
  }

  Future<String> newTxId() async {
    final sp = await _sp;
    final next = (sp.getInt(_kLastTxId) ?? 0) + 1;
    await sp.setInt(_kLastTxId, next);
    return next.toString();
  }
}
