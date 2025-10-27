import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// صفحه ساخت QR برای نمایش مبلغ/تراکنش
class GenerateQrScreen extends StatelessWidget {
  const GenerateQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // آرگومان‌های ورودی از route
    final args = ModalRoute.of(context)?.settings.arguments;
    String amount = '0';
    if (args is Map && args['amount'] != null) {
      amount = args['amount'].toString();
    }

    // داده‌ای که داخل QR قرار می‌گیرد (می‌توان JSON هم گذاشت)
    final qrPayload = 'SOMA|MERCHANT|AMOUNT=$amount';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تولید QR پرداخت'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 220,
                gapless: true,
              ),
              const SizedBox(height: 16),
              Text('مبلغ: $amount',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'خریدار این QR را اسکن می‌کند تا پرداخت انجام شود.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
