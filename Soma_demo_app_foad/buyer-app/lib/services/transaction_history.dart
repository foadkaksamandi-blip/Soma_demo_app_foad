import 'local_db.dart';
import '../models/transaction_log.dart';

class TransactionHistoryService {
  static final List<TransactionLog> _logs = [];

  static void addTransaction({
    required String method,
    required int amount,
  }) {
    final log = TransactionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      amount: amount,
      date: DateTime.now(),
    );
    _logs.add(log);
    LocalDB.instance.addTransaction(log.toJson());
  }

  static List<TransactionLog> getAllLogs() {
    return List.unmodifiable(_logs);
  }

  static void clearLogs() {
    _logs.clear();
    LocalDB.instance.clearTransactions();
  }
}
