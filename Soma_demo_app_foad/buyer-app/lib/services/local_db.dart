// buyer-app/lib/services/local_db.dart
/// Local in-memory DB (demo)
/// NOTE: این دمو است و پایدار نیست. برای PoC کافی است.
class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  // موجودی‌های خریدار (چهار کیف مستقل برای دمو)
  int buyerBalance = 1_000_000;       // نقد/عادی
  int buyerSubsidy = 500_000;         // یارانه
  int buyerEmergency = 300_000;       // اضطراری
  int buyerCBDC = 200_000;            // رمز ارز ملی

  /// برگرداندن موجودی یک کیف بر اساس منبع انتخابی
  int getWalletBalance(String source) {
    switch (source) {
      case 'یارانه':
        return buyerSubsidy;
      case 'اضطراری':
        return buyerEmergency;
      case 'رمز ارز ملی':
        return buyerCBDC;
      default:
        return buyerBalance;
    }
  }

  /// بروزرسانی موجودی یک کیف (delta می‌تواند منفی باشد)
  void addToWallet(String source, int delta) {
    switch (source) {
      case 'یارانه':
        buyerSubsidy += delta;
        if (buyerSubsidy < 0) buyerSubsidy = 0;
        break;
      case 'اضطراری':
        buyerEmergency += delta;
        if (buyerEmergency < 0) buyerEmergency = 0;
        break;
      case 'رمز ارز ملی':
        buyerCBDC += delta;
        if (buyerCBDC < 0) buyerCBDC = 0;
        break;
      default:
        buyerBalance += delta;
        if (buyerBalance < 0) buyerBalance = 0;
        break;
    }
  }

  /// افزایش تستی موجودی عادی (برای FAB)
  void addBuyerBalance(int delta) {
    buyerBalance += delta;
    if (buyerBalance < 0) buyerBalance = 0;
  }
}
