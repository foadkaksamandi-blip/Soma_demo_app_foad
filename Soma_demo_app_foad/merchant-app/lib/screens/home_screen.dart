import 'package:flutter/material.dart';
import 'bluetooth_receive_screen.dart';
import 'generate_qr_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما - فروشنده')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('موجودی: 0 تومان',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BluetoothReceiveScreen()),
                );
              },
              child: const Text('دریافت با بلوتوث'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GenerateQRScreen()),
                );
              },
              child: const Text('دریافت با QR کد'),
            ),
          ],
        ),
      ),
    );
  }
}
