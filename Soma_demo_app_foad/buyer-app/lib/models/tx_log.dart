import 'package:intl/intl.dart';

class TransactionLog {
  final String id;              // کد/شناسه تراکنش
  final String method;          // bluetooth | qr | subsidy | emergency | cbdc
  final int amount;             // مبلغ (ریال)
  final String wallet;          // نوع منبع: account | subsidy | emergency | cbdc
  final DateTime createdAt;     // زمان ایجاد

  TransactionLog({
    required this.id,
    required this.method,
    required this.amount,
    required this.wallet,
    required this.createdAt,
  });

  String get formattedDate =>
      DateFormat('yyyy/MM/dd HH:mm:ss', 'fa').format(createdAt);

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'amount': amount,
        'wallet': wallet,
        'createdAt': createdAt.toIso8601String(),
      };

  static TransactionLog fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      id: json['id'] as String,
      method: json['method'] as String,
      amount: json['amount'] as int,
      wallet: json['wallet'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
