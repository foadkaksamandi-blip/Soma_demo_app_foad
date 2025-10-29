class LocalDB {
  // موجودی‌های اولیه آزمایشی
  static int buyerBalance = 1000000;   // عادی
  static int buyerSubsidy = 500000;    // یارانه
  static int buyerEmergency = 300000;  // اضطراری
  static int buyerCBDC = 200000;       // رمز ارز ملی

  static Future<void> addToWallet(String source, int amount) async {
    switch (source) {
      case 'عادی':
        buyerBalance += amount;
        break;
      case 'یارانه':
        buyerSubsidy += amount;
        break;
      case 'اضطراری':
        buyerEmergency += amount;
        break;
      case 'رمزارز':
      case 'رمز ارز ملی':
        buyerCBDC += amount;
        break;
      default:
        buyerBalance += amount;
    }
  }

  static Future<bool> tryPay(String source, int amount) async {
    bool ok = false;
    switch (source) {
      case 'عادی':
        if (buyerBalance >= amount) {
          buyerBalance -= amount; ok = true;
        }
        break;
      case 'یارانه':
        if (buyerSubsidy >= amount) {
          buyerSubsidy -= amount; ok = true;
        }
        break;
      case 'اضطراری':
        if (buyerEmergency >= amount) {
          buyerEmergency -= amount; ok = true;
        }
        break;
      case 'رمزارز':
      case 'رمز ارز ملی':
        if (buyerCBDC >= amount) {
          buyerCBDC -= amount; ok = true;
        }
        break;
      default:
        if (buyerBalance >= amount) {
          buyerBalance -= amount; ok = true;
        }
    }
    return ok;
  }
}
