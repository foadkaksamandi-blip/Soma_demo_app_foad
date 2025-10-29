import 'dart:convert';
import 'package:uuid/uuid.dart';

/// مدل رسید تراکنش
class TxReceipt {
  final String id;          // کد تراکنش
  final double amount;      // مبلغ
  final String method;      // bluetooth | qr
  final String source;      // balance | subsidy | emergency | crypto
  final DateTime timestamp; // زمان ثبت

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
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        method: j['method'] as String,
        source: j['source'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

/// سرویس تراکنش (درون‌حافظه‌ای برای دمو)
class TransactionService {
  /// موجودی‌های آزمایشی (سمت خریدار/فروشنده)
  double buyerBalance = 500000;
  double merchantBalance = 250000;

  /// آخرین رسید ثبت‌شده (برای نمایش پایین صفحه)
  TxReceipt? lastReceipt;

  /// تولید payload برای QR (فروشنده می‌سازد، خریدار اسکن می‌کند)
  String generateQrData(double amount) {
    final data = {
      "id": const Uuid().v4(),
      "amount": amount,
      "timestamp": DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// اعمال تراکنش موفق (کاهش از خریدار، افزایش به فروشنده) + ثبت رسید
  bool applyPayment({
    required double amount,
    required String method, // 'bluetooth' | 'qr'
    required String source, // 'balance' | 'subsidy' | 'emergency' | 'crypto'
  }) {
    if (amount <= 0) return false;
    if (buyerBalance < amount) return false;

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

  /// دسترسی به رسید آخر (برای نمایش UI)
  TxReceipt? getLastReceipt() => lastReceipt;

  /// افزایش موجودی آزمایشی خریدار
  void addBuyerTestFunds(double amount) {
    buyerBalance += amount;
  }
}
