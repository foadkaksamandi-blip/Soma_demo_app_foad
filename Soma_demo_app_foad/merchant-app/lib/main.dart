import 'package:flutter/material.dart';
import 'screens/generate_qr_screen.dart';
import 'screens/bluetooth_receive_screen.dart';

void main() {
  runApp(const SomaMerchantApp());
}

class SomaMerchantApp extends StatelessWidget {
  const SomaMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Offline Soma — Merchant',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MerchantHomePage(),
    );
  }
}

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  final TextEditingController _amountController = TextEditingController();
  String _status = '';
  int _amount = 0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _navigateToBluetooth() {
    if (_validateAmount()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BluetoothReceiveScreen(amount: _amount),
        ),
      );
    }
  }

  void _navigateToQR() {
    if (_validateAmount()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GenerateQrScreen(amount: _amount),
        ),
      );
    }
  }

  bool _validateAmount() {
    try {
      _amount = int.parse(_amountController.text.trim());
      if (_amount <= 0) throw Exception();
      return true;
    } catch (_) {
      setState(() => _status = 'مبلغ وارد شده معتبر نیست.');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('App Offline Soma — Merchant')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('مبلغ تراکنش (تومان):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'مثلاً ۵۰۰۰۰',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _navigateToBluetooth,
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('دریافت بلوتوث'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToQR,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('نمایش QR'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
