// buyer-app/lib/models/tx_log.dart
import 'dart:math';

class TxLog {
  final String id;
  final int amount;
  final String source;        // عادی / یارانه / اضطراری / رمز ارز ملی
  final String method;        // QR / Bluetooth
  final String counterparty;  // merchant / buyer
  final DateTime at;

  TxLog({
    required this.id,
    required this.amount,
    required this.source,
    required this.method,
    required this.counterparty,
    required this.at,
  });

  factory TxLog.success({
    required int amount,
    required String source,
    required String method,
    required String counterparty,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = Random().nextInt(9999).toString().padLeft(4, '0');
    return TxLog(
      id: 'SOMA-$ts-$r',
      amount: amount,
      source: source,
      method: method,
      counterparty: counterparty,
      at: DateTime.now(),
    );
  }

  Map<String, String> toMap() => {
        'ID': id,
        'AMOUNT': amount.toString(),
        'SOURCE': source,
        'METHOD': method,
        'CP': counterparty,
        'TS': at.millisecondsSinceEpoch.toString(),
      };

  static TxLog fromMap(Map<String, String> m) {
    return TxLog(
      id: m['ID'] ?? '',
      amount: int.tryParse(m['AMOUNT'] ?? '0') ?? 0,
      source: m['SOURCE'] ?? 'عادی',
      method: m['METHOD'] ?? 'QR',
      counterparty: m['CP'] ?? 'merchant',
      at: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(m['TS'] ?? '0') ?? 0,
        isUtc: false,
      ),
    );
  }
}
