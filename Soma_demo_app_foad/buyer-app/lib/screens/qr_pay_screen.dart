import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrReceiptScreen extends StatelessWidget {
  const QrReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    final payload = args['payload'] as String? ?? '{}';
    const Color successGreen = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('رسید پرداخت (اسکن توسط فروشنده)'),
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(data: payload, size: 260),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('لطفاً فروشنده این QR را اسکن کند تا دریافت نهایی ثبت شود.',
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
