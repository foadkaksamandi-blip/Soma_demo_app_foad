class LocalDBMerchant {
  LocalDBMerchant._();
  static final instance = LocalDBMerchant._();

  int _merchantBalance = 0;

  Future<int> get balance async => _merchantBalance;

  Future<void> add(int v) async { _merchantBalance += v; }
}
