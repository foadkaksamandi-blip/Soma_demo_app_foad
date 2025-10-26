/// LocalDB ساده و درون‌حافظه‌ای برای دمو واقعی (Buyer)
class LocalDB {
  LocalDB._();
  static final LocalDB instance = LocalDB._();

  int _buyerBalance = 2000000;
  final List<Map<String, dynamic>> _buyerHistory = [];

  int get buyerBalance => _buyerBalance;

  void addBuyerBalance(int delta) {
    _buyerBalance += delta;
  }

  void addBuyerTx({
    required String txId,
    required int amount,
    required String method, // 'BT' | 'QR'
    required int ts,
    required String status, // 'SUCCESS' | 'FAIL' | 'PENDING'
  }) {
    _buyerHistory.add({
      'tx_id': txId,
      'amount': amount,
      'method': method,
      'ts': ts,
      'status': status,
    });
  }

  List<Map<String, dynamic>> get buyerHistory => List.unmodifiable(_buyerHistory);
}
