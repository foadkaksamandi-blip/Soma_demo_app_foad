// File: buyer-app/lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'bluetooth_pay_screen.dart';
import 'scan_qr_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما — خریدار')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('پرداخت با بلوتوث'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothPayScreen()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('پرداخت با QR'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanQrScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
