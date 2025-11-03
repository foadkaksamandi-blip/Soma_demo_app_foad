import 'local_db.dart';
import '../models/tx_log.dart';

class TransactionServiceMerchant {
  TransactionServiceMerchant._();
  static final instance = TransactionServiceMerchant._();

  Future<void> applyQrReceive({
    required LocalDBMerchant db,
    required int amount,
  }) async {
    db.addBalance(amount);
    final tx = TxLog.success(
      amount: amount,
      source: 'QR',
      method: 'QR',
      counterparty: 'buyer',
    );
    _logs.add(tx);
  }

  final List<TxLog> _logs = [];
  List<TxLog> get logs => List.unmodifiable(_logs);
}
