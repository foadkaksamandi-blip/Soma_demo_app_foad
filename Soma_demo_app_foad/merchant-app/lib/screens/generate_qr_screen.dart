import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/transaction_service.dart';

class GenerateQrScreen extends StatelessWidget {
  final double amount;
  final TransactionService tx;

  const GenerateQrScreen({
    super.key,
    required this.amount,
    required this.tx,
  });

  Color get _primary => const Color(0xFF27AE60);
  Color get _success => const Color(0xFF1ABC9C);

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('تولید QR برای خریدار'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 260,
                foregroundColor: _primary,
              ),
              const SizedBox(height: 20),
              Text('مبلغ: ${amount.toInt()} ریال',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _success,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  tx.merchantBalance += amount;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _success,
                      content: Text('تراکنش آماده اسکن توسط خریدار'),
                    ),
                  );
                },
                label: const Text('آماده برای اسکن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
