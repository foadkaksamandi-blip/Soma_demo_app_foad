import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  bool isScanning = false;
  bool secure = true; // اتصال ایمن (نمایشی)
  String? foundDeviceName;

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _startScan() async {
    setState(() {
      isScanning = true;
      foundDeviceName = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isScanning = false;
      foundDeviceName = 'SOMA-Merchant-A30';
    });
  }

  void _pay() {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _toast('مبلغ را وارد کنید');
      return;
    }
    if (foundDeviceName == null) {
      _toast('ابتدا به دستگاه فروشنده متصل شوید');
      return;
    }
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('مبلغ معتبر نیست');
      return;
    }
    final txId = _genTxId();
    _showSuccess(amount, txId);
  }

  String _genTxId() {
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch.toString().substring(8);
    return 'SOMA-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$ts';
    // نمونه: SOMA-20251026-123456
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
              const SizedBox(height: 8),
              Text('اتصال ایمن: ${secure ? "بله" : "خیر"}'),
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
        title: const Text('پرداخت با بلوتوث', textDirection: TextDirection.rtl),
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
            // اسکن/یافتن دستگاه
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(primaryTurquoise),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isScanning ? 'در حال جستجوی دستگاه...' : 'جستجوی دستگاه فروشنده',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: isScanning ? null : _startScan,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: Text(isScanning ? 'در حال جستجو...' : 'اسکن بلوتوث'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTurquoise,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: successGreen),
                      const SizedBox(width: 6),
                      Text(foundDeviceName == null ? 'دستگاهی پیدا نشد' : 'پیدا شد: $foundDeviceName'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // اتصال ایمن
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(primaryTurquoise),
              child: Row(
                children: [
                  Switch(
                    value: secure,
                    onChanged: (v) => setState(() => secure = v),
                    activeColor: successGreen,
                  ),
                  const SizedBox(width: 8),
                  const Text('اتصال ایمن'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // پرداخت
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _pay,
                icon: const Icon(Icons.check),
                label: const Text('پرداخت'),
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
