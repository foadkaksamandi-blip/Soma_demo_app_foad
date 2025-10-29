import '../models/transaction_log.dart';
import 'local_db.dart';

/// ثبت و بازیابی تاریخچه تراکنش‌ها (سمت خریدار)
class TransactionHistoryService {
  static final TransactionHistoryService _i = TransactionHistoryService._();
  TransactionHistoryService._();
  factory TransactionHistoryService() => _i;

  Future<void> add({
    required String method,
    required int amount,
    required String wallet,
  }) async {
    final log = TransactionLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      amount: amount,
      wallet: wallet,
      createdAt: DateTime.now(),
    );
    // ذخیره در DB لوکال (پیاده‌سازی LocalDB قبلاً موجود است)
    LocalDB.instance.addTransaction(log.toJson());
  }

  Future<List<TransactionLog>> getAll() async {
    final list = LocalDB.instance.getTransactions();
    return list.map((e) => TransactionLog.fromJson(e)).toList();
  }

  Future<void> clear() async {
    LocalDB.instance.clearTransactions();
  }
}
