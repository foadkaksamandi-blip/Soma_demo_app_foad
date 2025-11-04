// File: buyer-app/lib/screens/bluetooth_pay_screen.dart
import 'package:flutter/material.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  bool isConnected = false;
  String selectedSource = 'اصلی';
  final TextEditingController _amountController = TextEditingController();

  void _connect() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      isConnected = true;
    });
  }

  void _submit() {
    if (!isConnected) return;
    if (_amountController.text.isEmpty) return;
    Navigator.of(context).pop({
      'amount': int.parse(_amountController.text),
      'source': selectedSource,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت از طریق بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _connect,
              child: const Text('اتصال به فروشنده'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isConnected ? 'متصل شد' : 'در انتظار اتصال'),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedSource,
              items: const [
                DropdownMenuItem(value: 'اصلی', child: Text('حساب اصلی')),
                DropdownMenuItem(value: 'یارانه‌ای', child: Text('یارانه‌ای')),
                DropdownMenuItem(value: 'اضطراری ملی', child: Text('اضطراری ملی')),
              ],
              onChanged: (v) => setState(() => selectedSource = v!),
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
              onPressed: _submit,
              child: const Text('پرداخت'),
            ),
          ],
        ),
      ),
    );
  }
}
