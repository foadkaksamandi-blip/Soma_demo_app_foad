import 'package:flutter/material.dart';
import 'screens/scan_qr_screen.dart';
import 'screens/bluetooth_pay_screen.dart';

void main() {
  runApp(const SomaBuyerApp());
}

class SomaBuyerApp extends StatelessWidget {
  const SomaBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Offline Soma — Buyer',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const BuyerHomePage(),
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
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
          builder: (_) => BluetoothPayScreen(amount: _amount),
        ),
      );
    }
  }

  void _navigateToQR() {
    if (_validateAmount()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanQrScreen(amount: _amount),
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
        appBar: AppBar(title: const Text('App Offline Soma — Buyer')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text('مبلغ خرید (تومان):',
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
                    label: const Text('پرداخت بلوتوث'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _navigateToQR,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('پرداخت QR'),
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
