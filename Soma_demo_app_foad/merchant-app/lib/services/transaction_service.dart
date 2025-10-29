import 'dart:convert';
import 'package:uuid/uuid.dart';

/// مدل رسید تراکنش (سمت فروشنده)
class TxReceipt {
  final String id;
  final double amount;
  final String method;  // bluetooth | qr
  final String source;  // balance | subsidy | emergency | crypto
  final DateTime timestamp;

  TxReceipt({
    required this.id,
    required this.amount,
    required this.method,
    required this.source,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'method': method,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
      };

  static TxReceipt fromJson(Map<String, dynamic> j) => TxReceipt(
        id: j['id'],
        amount: (j['amount'] as num).toDouble(),
        method: j['method'],
        source: j['source'],
        timestamp: DateTime.parse(j['timestamp']),
      );
}

/// سرویس تراکنش محلی (برای تست)
class TransactionService {
  double merchantBalance = 250000;
  double buyerBalance = 500000;
  TxReceipt? lastReceipt;

  /// دریافت پول (بلوتوث یا QR)
  bool receivePayment({
    required double amount,
    required String method,
    required String source,
  }) {
    if (amount <= 0) return false;
    buyerBalance -= amount;
    merchantBalance += amount;

    lastReceipt = TxReceipt(
      id: const Uuid().v4(),
      amount: amount,
      method: method,
      source: source,
      timestamp: DateTime.now(),
    );
    return true;
  }

  String createQrData(double amount) {
    final data = {
      "id": const Uuid().v4(),
      "amount": amount,
      "timestamp": DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  TxReceipt? getLastReceipt() => lastReceipt;
}
