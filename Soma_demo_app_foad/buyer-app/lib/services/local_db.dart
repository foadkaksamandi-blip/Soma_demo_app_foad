import 'package:shared_preferences/shared_preferences.dart';

class LocalDB {
  LocalDB._();
  static final instance = LocalDB._();

  int buyerBalance = 800000;
  int buyerSubsidyBalance = 200000;
  int buyerEmergencyBalance = 150000;
  int buyerCbdcBalance = 300000;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    buyerBalance = prefs.getInt('buyerBalance') ?? 800000;
    buyerSubsidyBalance = prefs.getInt('buyerSubsidyBalance') ?? 200000;
    buyerEmergencyBalance = prefs.getInt('buyerEmergencyBalance') ?? 150000;
    buyerCbdcBalance = prefs.getInt('buyerCbdcBalance') ?? 300000;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('buyerBalance', buyerBalance);
    await prefs.setInt('buyerSubsidyBalance', buyerSubsidyBalance);
    await prefs.setInt('buyerEmergencyBalance', buyerEmergencyBalance);
    await prefs.setInt('buyerCbdcBalance', buyerCbdcBalance);
  }

  void applyQrPaymentFromSource({required String source, required int amount}) {
    switch (source) {
      case 'یارانه':
        buyerSubsidyBalance -= amount;
        break;
      case 'اضطراری':
        buyerEmergencyBalance -= amount;
        break;
      case 'رمز ارز ملی':
        buyerCbdcBalance -= amount;
        break;
      default:
        buyerBalance -= amount;
    }
    save();
  }
}
