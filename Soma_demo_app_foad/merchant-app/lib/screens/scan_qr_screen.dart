import 'package:flutter/material.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool scanned = false;
  int receivedAmount = 0;

  void _simulateScan() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      scanned = true;
      receivedAmount = 20000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR برای دریافت')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _simulateScan,
              child: const Text('شروع اسکن'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(scanned ? Icons.qr_code_2 : Icons.qr_code,
                    color: scanned ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(scanned ? 'کد دریافت شد' : 'در انتظار اسکن'),
              ],
            ),
            const SizedBox(height: 16),
            Text('مبلغ دریافتی: $receivedAmount ریال'),
          ],
        ),
      ),
    );
  }
}
