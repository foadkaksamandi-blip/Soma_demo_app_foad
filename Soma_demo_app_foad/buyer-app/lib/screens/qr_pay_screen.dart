import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QrPayScreen extends StatefulWidget {
  const QrPayScreen({super.key});

  @override
  State<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends State<QrPayScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  String? scannedData; // نمایش داده اسکن‌شده (نمایشی)

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _scan() async {
    // در نسخه فعلی نمایشی: داده ساختگی
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      scannedData = '{"type":"soma_tx","amount":500000,"tx_id":"SOMA-QR-DEMO"}';
    });
    _toast('QR دریافت شد (نمایشی)');
  }

  void _confirm() {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _toast('مبلغ را وارد کنید');
      return;
    }
    if (scannedData == null) {
      _toast('ابتدا QR را اسکن کنید');
      return;
    }
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('مبلغ معتبر نیست');
      return;
    }
    // نمایشی: موفق
    final txId = _genTxId();
    _showSuccess(amount, txId);
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

  void _showSuccess(int amount, String txId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('پرداخت موفق', textDirection: TextDirection.rtl),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مبلغ: ${_fmt(amount)} ریال'),
              const SizedBox(height: 8),
              Text('کد تراکنش: $txId'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشه'),
          )
        ],
      ),
    );
    _toast('پرداخت با موفقیت انجام شد', ok: true);
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        title: const Text('پرداخت با QR کد', textDirection: TextDirection.rtl),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // مبلغ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(primaryTurquoise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مبلغ پرداختی'),
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
            // اسکن QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(primaryTurquoise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اسکن QR فروشنده'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('اسکن QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTurquoise,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(scannedData == null ? 'هنوز چیزی اسکن نشده' : 'داده: $scannedData'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // تأیید پرداخت
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check),
                label: const Text('تأیید و پرداخت'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: successGreen,
                  foregroundColor: Colors.white,
                ),
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
