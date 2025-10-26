import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../services/local_db.dart';

class QrPayScreen extends StatefulWidget {
  const QrPayScreen({super.key});

  @override
  State<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends State<QrPayScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  bool _scanning = false;
  String? _lastTxnId;

  void _showSnack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87,
      ),
    );
  }

  void _onDetect(BarcodeCapture cap) {
    if (_scanning) return;
    if (cap.barcodes.isEmpty) return;

    setState(() => _scanning = true);
    try {
      final raw = cap.barcodes.first.rawValue ?? '';
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final int merchantAmount = data['amount'] as int? ?? 0;
      final int inputAmount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      if (inputAmount <= 0) {
        _showSnack('مبلغ را وارد کنید.');
        setState(() => _scanning = false);
        return;
      }

      if (merchantAmount != inputAmount) {
        _showSnack('مبلغ وارد شده با مبلغ QR فروشنده یکسان نیست.');
        setState(() => _scanning = false);
        return;
      }

      // پرداخت موفق: کسر از موجودی خریدار
      LocalDB.instance.addBuyerBalance(-inputAmount);
      final txnId = const Uuid().v4();
      setState(() => _lastTxnId = txnId);

      _showSnack('پرداخت موفق انجام شد. کد تراکنش: $txnId', ok: true);
    } catch (_) {
      _showSnack('QR نامعتبر است.');
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
    const Color successGreen = Color(0xFF27AE60);

    return const Directionality(
      textDirection: TextDirection.rtl,
      child: _QrPayBody(),
    );
  }
}

class _QrPayBody extends StatefulWidget {
  const _QrPayBody();

  @override
  State<_QrPayBody> createState() => _QrPayBodyState();
}

class _QrPayBodyState extends State<_QrPayBody> {
  final TextEditingController _amountCtrl = TextEditingController();
  bool _isScannerOpen = false;
  String? _txnId;

  void _showSnack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87,
      ),
    );
  }

  void _openScanner() {
    if ((_amountCtrl.text).trim().isEmpty) {
      _showSnack('ابتدا مبلغ را وارد کنید.');
      return;
    }
    setState(() => _isScannerOpen = true);
  }

  void _onDetect(BarcodeCapture cap) {
    if (cap.barcodes.isEmpty) return;
    try {
      final raw = cap.barcodes.first.rawValue ?? '';
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final int merchantAmount = data['amount'] as int? ?? 0;
      final int inputAmount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      if (merchantAmount != inputAmount) {
        _showSnack('مبلغ وارد شده با مبلغ QR فروشنده یکسان نیست.');
        return;
      }

      // انجام پرداخت
      LocalDB.instance.addBuyerBalance(-inputAmount);
      final id = const Uuid().v4();
      setState(() => _txnId = id);
      _showSnack('پرداخت موفق شد. کد تراکنش: $id', ok: true);
    } catch (_) {
      _showSnack('QR نامعتبر است.');
    } finally {
      setState(() => _isScannerOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
    const Color successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پرداخت با QR'),
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('مبلغ پرداخت'),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openScanner,
              style: ElevatedButton.styleFrom(backgroundColor: primaryTurquoise),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('اسکن QR فروشنده'),
            ),
            if (_txnId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('کد تراکنش: $_txnId'),
              ),
            ],
            const SizedBox(height: 16),
            if (_isScannerOpen)
              SizedBox(
                height: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: _onDetect,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
