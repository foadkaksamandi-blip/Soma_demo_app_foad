import 'package:shared_preferences/shared_preferences.dart';

class LocalDBMerchant {
  LocalDBMerchant._();
  static final instance = LocalDBMerchant._();

  String merchantId = 'merchant001';
  int merchantBalance = 500000;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    merchantBalance = prefs.getInt('merchantBalance') ?? 500000;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('merchantBalance', merchantBalance);
  }

  void addBalance(int amount) {
    merchantBalance += amount;
    save();
  }
}
