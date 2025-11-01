import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  Future<bool> receiveAmount(int amount, String wallet) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'wallet_$wallet';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + amount);
    return true;
  }
}
