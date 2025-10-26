import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPayScreen extends StatelessWidget {
  const QrPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ورودی اختیاری مبلغ از صفحه قبل
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final amount = (args['amount'] ?? '').toString().trim();
    final payload = amount.isNotEmpty
        ? 'soma://pay?amount=$amount&ts=${DateTime.now().millisecondsSinceEpoch}'
        : 'soma://pay?demo=1&ts=${DateTime.now().millisecondsSinceEpoch}';

    const successGreen = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          title: const Text('پرداخت با QR'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: payload, size: 260),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  amount.isNotEmpty
                      ? 'این QR برای مبلغ $amount ریال تولید شد.'
                      : 'دموی پرداخت QR (بدون مبلغ مشخص).',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
