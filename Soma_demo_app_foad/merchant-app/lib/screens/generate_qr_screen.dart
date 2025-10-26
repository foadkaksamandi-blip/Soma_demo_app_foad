import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  String? qrPayload; // داده QR (نمایشی)

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _makeQr() {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _toast('مبلغ را وارد کنید');
      return;
    }
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('مبلغ معتبر نیست');
      return;
    }
    final txId = _genTxId();
    final json = '{"type":"soma_tx","amount":$amount,"tx_id":"$txId"}';
    setState(() => qrPayload = json);
    _toast('QR تولید شد (نمایشی)', ok: true);
  }

  String _genTxId() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch.toString().substring(8);
    return 'SOMA-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$ts';
  }

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        title: const Text('تولید QR فروش', textDirection: TextDirection.rtl),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // مبلغ فروش
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(successGreen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مبلغ فروش'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'مثلاً ۵۰۰٬۰۰۰',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // تولید QR
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _makeQr,
                icon: const Icon(Icons.qr_code),
                label: const Text('تولید QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // پیش‌نمایش داده QR (نمایشی)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(primaryTurquoise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('داده QR (نمایشی)'),
                  const SizedBox(height: 8),
                  Text(qrPayload ?? 'هنوز تولید نشده'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _box(Color c) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      );
}
