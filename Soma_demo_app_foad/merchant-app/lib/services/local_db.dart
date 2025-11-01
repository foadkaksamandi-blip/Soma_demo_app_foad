class LocalDBMerchant {
  LocalDBMerchant._();
  static final LocalDBMerchant instance = LocalDBMerchant._();

  int _main = 2500000;
  int _subsidy = 0;
  int _emergency = 0;
  int _crypto = 0;

  int get merchantBalance => _main;

  Map<String, int> get balances => {
        'main': _main,
        'subsidy': _subsidy,
        'emergency': _emergency,
        'crypto': _crypto,
      };

  Future<void> addIncome({required String wallet, required int amount}) async {
    if (amount <= 0) return;
    switch (wallet) {
      case 'main':
        _main += amount;
        break;
      case 'subsidy':
        _subsidy += amount;
        break;
      case 'emergency':
        _emergency += amount;
        break;
      case 'crypto':
        _crypto += amount;
        break;
      default:
        _main += amount;
        break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}
