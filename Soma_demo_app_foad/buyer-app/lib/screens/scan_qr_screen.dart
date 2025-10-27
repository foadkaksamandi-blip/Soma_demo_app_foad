import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handled = false;
  int _expectedAmount = 0;
  String _source = 'یارانه';

  @override
  void initState() {
    super.initState();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _expectedAmount = (args['expectedAmount'] as int?) ?? 0;
    _source = (args['source'] as String?) ?? 'یارانه';
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    _handled = true;

    final raw = codes.first.rawValue ?? '';
    // نمونه داده دریافتی: SOMA|MERCHANT|AMOUNT=xxxx|...
    int scannedAmount = 0;
    final parts = raw.split('|');
    for (final p in parts) {
      if (p.startsWith('AMOUNT=')) {
        scannedAmount = int.tryParse(p.split('=').last) ?? 0;
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأیید پرداخت'),
        content: Text(
          'پرداخت با QR شناسایی شد.\n'
          'مبلغ: ${scannedAmount > 0 ? scannedAmount : _expectedAmount} ریال\n'
          'منبع: $_source',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('پرداخت با QR ثبت شد (دمو)')),
              );
              Navigator.pop(context);
            },
            child: const Text('پرداخت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        title: const Text('اسکن QR'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _expectedAmount > 0
                    ? 'مبلغ مورد انتظار: $_expectedAmount ریال'
                    : 'QR را در کادر بگیرید',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
