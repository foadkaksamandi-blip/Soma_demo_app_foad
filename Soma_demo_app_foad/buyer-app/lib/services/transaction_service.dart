import '../models/tx_log.dart';
import 'bluetooth_service.dart';
import 'qr_service.dart';
import 'transaction_history.dart';

class TransactionService {
  final BluetoothService _bt = BluetoothService();
  final TransactionHistoryService _history = TransactionHistoryService();

  Future<TxLog> performBluetoothPayment(int amount, String source) async {
    await _bt.connectToMerchant();
    final id = await _bt.sendPayment(amount);
    final log = TxLog.success(
      amount: amount,
      source: source,
      method: 'Bluetooth',
      counterparty: 'merchant',
    );
    await _history.add(log);
    await _bt.disconnect();
    return log;
  }

  Future<TxLog> performQrPayment(int amount, String source) async {
    final tx = TxLog.success(
      amount: amount,
      source: source,
      method: 'QR',
      counterparty: 'merchant',
    );
    await _history.add(tx);
    return tx;
  }
}
