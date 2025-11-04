import 'package:flutter/material.dart';
import 'bluetooth_receive_screen.dart';
import 'generate_qr_screen.dart';

class MerchantHomePage extends StatelessWidget {
  const MerchantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما — فروشنده')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('دریافت با بلوتوث'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothReceiveScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('نمایش QR برای پرداخت'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GenerateQrScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
