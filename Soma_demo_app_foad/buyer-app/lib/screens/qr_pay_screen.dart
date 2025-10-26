import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrPayScreen extends StatelessWidget {
  const QrPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final payload = args['payload'] as String? ?? '';
    const successGreen = Color(0xFF27AE60);

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
              QrImageView(data: payload.isEmpty ? 'PAYLOAD' : payload, size: 260),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('را اسکن کنید تا دریافت‌کننده روی اپ فروشنده تایید شود.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
