import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'bluetooth_screen.dart';
import 'qr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double balance = 250000;
  List<String> transactions = [];

  void addTransaction(String type, double amount) {
    final now = DateTime.now();
    final time = DateFormat('HH:mm:ss').format(now);
    final date = DateFormat('yyyy-MM-dd').format(now);
    setState(() {
      balance -= amount;
      transactions.add('$type - مبلغ: $amount - $date $time');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما - خریدار')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('موجودی: ${balance.toStringAsFixed(0)} تومان',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BluetoothScreen()),
                );
              },
              child: const Text('پرداخت با بلوتوث'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScreen()),
                );
              },
              child: const Text('پرداخت با QR کد'),
            ),
            const SizedBox(height: 20),
            const Text('تراکنش‌ها:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(transactions[index]));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
