import 'package:intl/intl.dart';

class TransactionLog {
  final String id;
  final String method;
  final int amount;
  final DateTime date;

  TransactionLog({
    required this.id,
    required this.method,
    required this.amount,
    required this.date,
  });

  String get formattedDate =>
      DateFormat('yyyy/MM/dd HH:mm:ss', 'fa').format(date);

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  static TransactionLog fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      id: json['id'],
      method: json['method'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
    );
  }
}
