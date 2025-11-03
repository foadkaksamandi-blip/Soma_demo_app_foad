import 'package:flutter/material.dart';

class BluetoothScreen extends StatelessWidget {
  const BluetoothScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت بلوتوثی')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('در حال جستجوی دستگاه فروشنده...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تراکنش موفق!'),
                ));
                Navigator.pop(context);
              },
              child: const Text('شروع پرداخت'),
            ),
          ],
        ),
      ),
    );
  }
}
