import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  String? _qrData;

  void _makeQr() {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ معتبر وارد کنید.')),
      );
      return;
    }
    final data = jsonEncode({
      'type': 'soma_merchant_request',
      'amount': amount,
      'ts': DateTime.now().toIso8601String(),
    });
    setState(() => _qrData = data);
  }

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: _GenerateQrBody(),
    );
  }
}

class _GenerateQrBody extends StatefulWidget {
  const _GenerateQrBody();

  @override
  State<_GenerateQrBody> createState() => _GenerateQrBodyState();
}

class _GenerateQrBodyState extends State<_GenerateQrBody> {
  final TextEditingController _amountCtrl = TextEditingController();
  String? _qrData;

  void _makeQr() {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبلغ معتبر وارد کنید.')));
      return;
    }
    final payload = jsonEncode({
      'type': 'soma_merchant_request',
      'amount': amount,
      'ts': DateTime.now().toIso8601String(),
    });
    setState(() => _qrData = payload);
  }

  @override
  Widget build(BuildContext context) {
    const Color successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تولید QR برای پرداخت'),
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('مبلغ فروش'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'مثلاً ۵۰۰۰۰۰',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _makeQr,
              icon: const Icon(Icons.qr_code),
              label: const Text('تولید QR'),
            ),
            const SizedBox(height: 16),
            if (_qrData != null)
              Center(
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
