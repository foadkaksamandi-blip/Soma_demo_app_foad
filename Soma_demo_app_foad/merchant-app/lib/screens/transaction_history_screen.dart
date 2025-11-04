import 'package:flutter/material.dart';
import '../models/tx_log.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TxLog> logs = [
      TxLog(
        id: 'SOMA-001',
        amount: 25000,
        source: 'اصلی',
        method: 'Bluetooth',
        at: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      TxLog(
        id: 'SOMA-002',
        amount: 120000,
        source: 'یارانه‌ای',
        method: 'QR',
        at: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه تراکنش‌ها')),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: Icon(
              log.method == 'QR' ? Icons.qr_code_2 : Icons.bluetooth,
              color: Colors.teal,
            ),
            title: Text('${log.amount} ریال'),
            subtitle: Text('${log.method} - ${log.source}'),
            trailing: Text('${log.at.hour}:${log.at.minute.toString().padLeft(2, '0')}'),
          );
        },
      ),
    );
  }
}
