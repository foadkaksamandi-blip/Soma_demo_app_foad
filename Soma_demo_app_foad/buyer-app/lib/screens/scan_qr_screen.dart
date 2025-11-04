// File: buyer-app/lib/screens/scan_qr_screen.dart
import 'package:flutter/material.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool scanned = false;
  final TextEditingController _amountController = TextEditingController();

  void _simulateScan() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() => scanned = true);
  }

  void _confirm() {
    if (_amountController.text.isEmpty || !scanned) return;
    Navigator.of(context).pop({
      'amount': int.parse(_amountController.text),
      'source': 'اصلی',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت با QR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _simulateScan,
              child: const Text('اسکن QR'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(scanned ? Icons.check_circle : Icons.qr_code_2,
                    color: scanned ? Colors.green : Colors.black54),
                const SizedBox(width: 8),
                Text(scanned ? 'کد QR اسکن شد' : 'در انتظار اسکن'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ (ریال)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirm,
              child: const Text('تأیید تراکنش'),
            ),
          ],
        ),
      ),
    );
  }
}
