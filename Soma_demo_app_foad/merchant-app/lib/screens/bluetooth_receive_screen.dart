import 'package:flutter/material.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  bool connected = false;
  int receivedAmount = 0;

  void _simulateReceive() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      connected = true;
      receivedAmount = 25000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _simulateReceive,
              child: const Text('در انتظار اتصال خریدار'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: connected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(connected ? 'تراکنش دریافت شد' : 'در حال انتظار'),
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
