import 'package:flutter/material.dart';
import 'screens/scan_qr_screen.dart';
import 'screens/bluetooth_pay_screen.dart';

void main() {
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Offline Soma — Buyer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2B6CB0)),
      routes: {
        '/qr': (_) => const QrScreen(),
        '/bt': (_) => const BluetoothPayScreen(),
      },
      home: const _Home(),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Offline Soma — Buyer')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/qr',
                  arguments: {'amount': 120000, 'wallet': 'main'}),
              child: const Text('Scan QR'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/bt',
                  arguments: {'amount': 120000, 'wallet': 'main'}),
              child: const Text('Bluetooth Pay'),
            ),
          ],
        ),
      ),
    );
  }
}
