import 'package:intl/intl.dart';

class LocalDB {
  static final LocalDB instance = LocalDB._internal();
  LocalDB._internal();

  int buyerBalance = 500000;
  int merchantBalance = 0;

  void addBuyerBalance(int amount) {
    buyerBalance += amount;
  }

  void addMerchantBalance(int amount) {
    merchantBalance += amount;
  }

  static String formatRials(int value) {
    final f = NumberFormat.decimalPattern('fa');
    return f.format(value);
  }
}
