import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../services/local_db.dart';
import '../services/transaction_history.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool handled = false;

  @override
  void reassemble() {
    super.reassemble();
    // برای hot-reload روی اندروید/ios
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String data) async {
    if (handled) return;
    handled = true;

    try {
      final Map<String, dynamic> payload = jsonDecode(data);
      final String type = payload['type']?.toString() ?? '';
      final int amount = (payload['amount'] is int)
          ? payload['amount'] as int
          : int.tryParse('${payload['amount']}') ?? 0;

      if (type != 'invoice' || amount <= 0) {
        _show('QR نامعتبر است.');
        Navigator.pop(context);
        return;
      }

      // کسر موجودی واقعی از کیفِ انتخابی کاربر (پیش‌فرض حساب)
      if (LocalDB.instance.buyerBalance < amount) {
        _show('موجودی کافی نیست.');
        Navigator.pop(context);
        return;
      }

      LocalDB.instance.addBuyerBalance(-amount); // کسر
      await TransactionHistoryService().add(
        method: 'qr',
        amount: amount,
        wallet: 'account', // اگر از صفحه اصلی wallet انتخاب می‌فرستی، می‌توانی از arguments بخوانی.
      );

      // نمایش QR تأییدی برای اسکن فروشنده (رسید پرداخت)
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('پرداخت موفق'),
          content: Text('مبلغ $amount ریال با QR پرداخت شد.\n'
              'اکنون فروشنده می‌تواند رسید را اسکن کند (در صفحهٔ دریافت خود).'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            )
          ],
        ),
      );

      Navigator.pop(context, {'paid': true, 'amount': amount});
    } catch (_) {
      _show('خواندن QR نامعتبر است.');
      Navigator.pop(context);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR')),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: (c) {
              controller = c;
              c.scannedDataStream.listen((scanData) {
                final code = scanData.code;
                if (code != null) _handleScan(code);
              });
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await controller?.toggleFlash();
                  setState(() {});
                },
                icon: const Icon(Icons.flash_on),
                label: const Text('فلش'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
