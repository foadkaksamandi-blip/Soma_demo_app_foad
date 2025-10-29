import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';

class GenerateQrScreen extends StatelessWidget {
  const GenerateQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final expectedAmount = args['expectedAmount'] is int ? args['expectedAmount'] as int : 0;

    final payload = jsonEncode({
      'type': 'invoice',
      'amount': expectedAmount,
      'merchant': true,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    return Scaffold(
      appBar: AppBar(title: const Text('QR دریافت مبلغ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImageView(data: payload, size: 220),
            const SizedBox(height: 16),
            Text('مبلغ مورد انتظار: $expectedAmount ریال'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // اینجا فقط QR صادر می‌شود؛ پس از اسکن موفق خریدار، افزایش موجودی سمت فروشنده در receive انجام می‌گیرد
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR برای خریدار آماده است.')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('آماده'),
            ),
          ],
        ),
      ),
    );
  }
}
