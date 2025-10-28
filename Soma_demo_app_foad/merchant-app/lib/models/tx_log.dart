// merchant-app/lib/models/tx_log.dart
class TxLog {
  final String id;            // کد تراکنش (مثلاً SOMA-20251028-123456)
  final int amount;           // مبلغ ریالی
  final String source;        // یارانه | اضطراری | رمز ارز ملی
  final String method;        // Bluetooth | QR
  final DateTime createdAt;   // زمان ثبت
  final String counterparty;  // طرف مقابل (buyer/merchant id اختیاری)
  final bool success;         // نتیجه

  TxLog({
    required this.id,
    required this.amount,
    required this.source,
    required this.method,
    required this.createdAt,
    required this.counterparty,
    required this.success,
  });

  factory TxLog.success({
    required int amount,
    required String source,
    required String method,
    String counterparty = 'buyer',
  }) {
    final now = DateTime.now();
    final code =
        'SOMA-${now.toIso8601String().replaceAll(RegExp(r"[^0-9]"), "")}-${now.millisecond}';
    return TxLog(
      id: code,
      amount: amount,
      source: source,
      method: method,
      createdAt: now,
      counterparty: counterparty,
      success: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'source': source,
        'method': method,
        'createdAt': createdAt.toIso8601String(),
        'counterparty': counterparty,
        'success': success,
      };

  factory TxLog.fromJson(Map<String, dynamic> j) => TxLog(
        id: j['id'] as String,
        amount: j['amount'] as int,
        source: j['source'] as String,
        method: j['method'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        counterparty: (j['counterparty'] as String?) ?? 'buyer',
        success: (j['success'] as bool?) ?? false,
      );
}
