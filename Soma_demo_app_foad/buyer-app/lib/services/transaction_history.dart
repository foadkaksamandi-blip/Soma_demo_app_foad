import '../models/tx_log.dart';

class TransactionHistoryService {
  TransactionHistoryService._();
  static final instance = TransactionHistoryService._();

  final List<TxLog> _logs = [];

  Future<void> logBuyerQrPayment({
    required int amount,
    required String source,
    required String merchantId,
  }) async {
    final tx = TxLog.success(
      amount: amount,
      source: source,
      method: 'QR',
      counterparty: merchantId,
    );
    _logs.add(tx);
  }

  List<TxLog> get logs => List.unmodifiable(_logs);
}
