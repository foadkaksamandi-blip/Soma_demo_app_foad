import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_db.dart';

class MerchantTransactionHistoryScreen extends StatelessWidget {
  const MerchantTransactionHistoryScreen({super.key});

  String _format(DateTime dt) =>
      DateFormat('yyyy/MM/dd HH:mm:ss', 'fa').format(dt);

  @override
  Widget build(BuildContext context) {
    final logs = LocalDBMerchant.instance.getTransactions(); // List<Map>
    return Scaffold(
      appBar: AppBar(
        title: const Text('تاریخچه تراکنش‌ها (فروشنده)'),
      ),
      body: logs.isEmpty
          ? const Center(child: Text('هیچ تراکنشی ثبت نشده است.'))
          : ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (ctx, i) {
                final e = logs[i];
                final ts = DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now();
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text('مبلغ: ${e['amount']} ریال'),
                  subtitle: Text('روش: ${e['method']} | ${_format(ts)}'),
                  trailing: Text(e['wallet'] ?? 'account'),
                );
              },
            ),
    );
  }
}
