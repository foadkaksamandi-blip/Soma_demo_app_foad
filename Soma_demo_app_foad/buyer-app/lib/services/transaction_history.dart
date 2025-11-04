import '../models/tx_log.dart';
import 'local_db.dart';

class TransactionHistoryService {
  final LocalDB _db = LocalDB();

  Future<List<TxLog>> getAll() => _db.getLogs();

  Future<void> add(TxLog log) async {
    await _db.saveLog(log);
  }

  Future<void> clear() async {
    await _db.clear();
  }
}
