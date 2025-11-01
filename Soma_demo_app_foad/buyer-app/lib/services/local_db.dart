import 'dart:math';

class LocalDB {
  LocalDB._();
  static final instance = LocalDB._();

  int _main = 2000000;
  int _subsidy = 1500000;
  int _emergency = 800000;
  int _cbdc = 0;

  Future<int> getBalance({String wallet = 'main'}) async {
    switch (wallet) {
      case 'subsidy': return _subsidy;
      case 'emergency': return _emergency;
      case 'cbdc': return _cbdc;
      default: return _main;
    }
  }

  Future<void> addBalance(int v, {String wallet='main'}) async {
    switch (wallet) {
      case 'subsidy': _subsidy += v; break;
      case 'emergency': _emergency += v; break;
      case 'cbdc': _cbdc += v; break;
      default: _main += v;
    }
  }

  Future<bool> spend(int v, {String wallet='main'}) async {
    int b = await getBalance(wallet: wallet);
    if (b < v) return false;
    switch (wallet) {
      case 'subsidy': _subsidy -= v; break;
      case 'emergency': _emergency -= v; break;
      case 'cbdc': _cbdc -= v; break;
      default: _main -= v;
    }
    return true;
  }

  String newTxId() {
    final rnd = Random().nextInt(900000) + 100000;
    return 'TX-${DateTime.now().millisecondsSinceEpoch}-$rnd';
  }
}
