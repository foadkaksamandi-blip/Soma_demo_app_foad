/// LocalDB ساده و درون‌حافظه‌ای برای اپ فروشنده (نسخه نمایشی)
class LocalDBMerchant {
  LocalDBMerchant._();
  static final LocalDBMerchant instance = LocalDBMerchant._();

  int _merchantBalance = 0;
  final List<Map<String, dynamic>> _merchantHistory = [];

  int get merchantBalance => _merchantBalance;

  void addMerchantBalance(int delta) {
    _merchantBalance += delta;
  }

  void addMerchantTx({
    required String txId,
    required int amount,
    required String method, // 'BT' | 'QR'
    required int ts,
    required String status, // 'SUCCESS' | 'FAIL'
  }) {
    _merchantHistory.add({
      'tx_id': txId,
      'amount': amount,
      'method': method,
      'ts': ts,
      'status': status,
    });
  }

  List<Map<String, dynamic>> get merchantHistory => List.unmodifiable(_merchantHistory);
}
