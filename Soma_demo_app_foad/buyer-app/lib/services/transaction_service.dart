import 'dart:convert';
import 'package:uuid/uuid.dart';

class TxReceipt {
  final String id;
  final double amount;
  final String method; // bluetooth | qr
  final String source; // balance | subsidy | emergency | crypto
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
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        method: j['method'] as String,
        source: j['source'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

class TransactionService {
  double buyerBalance = 5000000;
  double subsidyBalance = 1500000;
  double emergencyBalance = 800000;
  double cryptoBalance = 2500000;

  TxReceipt? lastReceipt;

  String generateQrPayload(double amount) {
    final data = {
      'id': const Uuid().v4(),
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  bool applyPayment({
    required double amount,
    required String method, // bluetooth | qr
    required String source, // balance | subsidy | emergency | crypto
  }) {
    if (amount <= 0) return false;

    double sourceBalance() {
      switch (source) {
        case 'subsidy':
          return subsidyBalance;
        case 'emergency':
          return emergencyBalance;
        case 'crypto':
          return cryptoBalance;
        default:
          return buyerBalance;
      }
    }

    void setSourceBalance(double v) {
      switch (source) {
        case 'subsidy':
          subsidyBalance = v;
          return;
        case 'emergency':
          emergencyBalance = v;
          return;
        case 'crypto':
          cryptoBalance = v;
          return;
        default:
          buyerBalance = v;
      }
    }

    if (sourceBalance() < amount) return false;

    setSourceBalance(sourceBalance() - amount);

    lastReceipt = TxReceipt(
      id: const Uuid().v4(),
      amount: amount,
      method: method,
      source: source,
      timestamp: DateTime.now(),
    );
    return true;
  }
}
