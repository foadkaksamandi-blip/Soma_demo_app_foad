import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple local key-value wallet DB for the demo.
/// Keys:
///  - wallet_main
///  - wallet_subsidy
///  - wallet_emergency
///  - wallet_crypto
class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _keyForWallet(String wallet) {
    switch (wallet) {
      case 'main':
        return 'wallet_main';
      case 'subsidy':
        return 'wallet_subsidy';
      case 'emergency':
        return 'wallet_emergency';
      case 'crypto':
        return 'wallet_crypto';
      default:
        return 'wallet_main';
    }
  }

  /// Returns current balance (rial) for given wallet.
  Future<int> balance(String wallet) async {
    final p = await _prefs;
    return p.getInt(_keyForWallet(wallet)) ?? 0;
  }

  /// Initializes demo balances if not set.
  Future<void> ensureSeed() async {
    final p = await _prefs;
    p.setInt('wallet_main', p.getInt('wallet_main') ?? 100000);
    p.setInt('wallet_subsidy', p.getInt('wallet_subsidy') ?? 50000);
    p.setInt('wallet_emergency', p.getInt('wallet_emergency') ?? 20000);
    p.setInt('wallet_crypto', p.getInt('wallet_crypto') ?? 300000);
  }

  /// Spend [amount] from [wallet]. Returns true on success.
  Future<bool> spend_amount(int amount, String wallet) async {
    if (amount <= 0) return false;
    final p = await _prefs;
    final k = _keyForWallet(wallet);
    final cur = p.getInt(k) ?? 0;
    if (cur < amount) return false;
    await p.setInt(k, cur - amount);
    return true;
    }

  /// Adds [amount] to [wallet]. (useful for merchant or refunds)
  Future<void> add_amount(int amount, String wallet) async {
    final p = await _prefs;
    final k = _keyForWallet(wallet);
    final cur = p.getInt(k) ?? 0;
    await p.setInt(k, cur + amount);
  }

  /// Generates a simple incremental tx id.
  Future<String> newTxId() async {
    final p = await _prefs;
    final n = (p.getInt('tx_seq') ?? 0) + 1;
    await p.setInt('tx_seq', n);
    return 'TX$n';
  }
}
