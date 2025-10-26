import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/local_db.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  bool _done = false;
  String? _msg;

  void _onDetect(BarcodeCapture cap) {
    if (_done) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      if (data['type'] == 'soma_receipt') {
        final amount = (data['amount'] as num).toInt();
        LocalDBMerchant.instance.addMerchantBalance(amount);
        setState(() {
          _msg = 'رسید معتبر دریافت شد. مبلغ $amount ریال اضافه شد.';
          _done = true;
        });
      } else {
        setState(() => _msg = 'کد معتبر رسید نیست.');
      }
    } catch (_) {
      setState(() => _msg = 'QR نامعتبر است.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اسکن رسید خریدار'),
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(onDetect: _onDetect),
            ),
            if (_msg != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_msg!, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
