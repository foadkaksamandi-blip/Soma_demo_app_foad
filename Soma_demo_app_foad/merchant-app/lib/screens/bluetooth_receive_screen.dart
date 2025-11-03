import 'package:flutter/material.dart';

class BluetoothReceiveScreen extends StatelessWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با بلوتوث')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching,
                size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('در حال انتظار برای پرداخت مشتری...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تراکنش دریافت شد!'),
                ));
                Navigator.pop(context);
              },
              child: const Text('پایان تراکنش'),
            ),
          ],
        ),
      ),
    );
  }
}
