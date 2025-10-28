class LocalDb {
  LocalDb._();
  static final instance = LocalDb._();

  int buyerBalance = 1000000;   // موجودی کیف پول
  int buyerSubsidy = 500000;    // یارانه
  int buyerEmergency = 300000;  // اضطراری
  int buyerCBDC = 200000;       // رمز ارز ملی

  void addToWallet(String source, int amount) {
    switch (source) {
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
    }
  }
}
