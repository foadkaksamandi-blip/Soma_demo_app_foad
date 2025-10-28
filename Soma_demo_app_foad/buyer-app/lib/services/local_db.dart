class LocalDb {
  // موجودی‌های اولیه (بدون underscore)
  static int buyerBalance   = 1000000; // کیف پول/حساب اصلی
  static int buyerSubsidy   = 500000;  // یارانه
  static int buyerEmergency = 300000;  // اضطراری
  static int buyerCBDC      = 200000;  // رمز ارز ملی

  // Helperهای خیلی ساده برای دمو
  static void addToWallet(String src, int amount) {
    switch (src) {
      case 'یارانه':
        buyerSubsidy += amount;
        break;
      case 'اضطراری':
        buyerEmergency += amount;
        break;
      case 'رمز ارز ملی':
        buyerCBDC += amount;
        break;
      default:
        buyerBalance += amount;
        break;
    }
  }

  static bool deductFromWallet(String src, int amount) {
    switch (src) {
      case 'یارانه':
        if (buyerSubsidy >= amount) {
          buyerSubsidy -= amount;
          return true;
        }
        break;
      case 'اضطراری':
        if (buyerEmergency >= amount) {
          buyerEmergency -= amount;
          return true;
        }
        break;
      case 'رمز ارز ملی':
        if (buyerCBDC >= amount) {
          buyerCBDC -= amount;
          return true;
        }
        break;
      default:
        if (buyerBalance >= amount) {
          buyerBalance -= amount;
          return true;
        }
    }
    return false;
  }
}
