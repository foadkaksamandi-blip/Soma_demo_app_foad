// merchant-app/lib/services/local_db.dart
/// Local in-memory DB (demo)
class LocalDBMerchant {
  LocalDBMerchant._();
  static final LocalDBMerchant instance = LocalDBMerchant._();

  int merchantBalance = 0;

  void addMerchantBalance(int delta) {
    merchantBalance += delta;
    if (merchantBalance < 0) merchantBalance = 0;
  }
}
