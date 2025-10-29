import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/transaction_service.dart';

class ScanQrScreen extends StatefulWidget {
  final double expectedAmount;   // مبلغ ورودی کاربر برای تطبیق
  final String source;           // balance | subsidy | emergency | crypto
  final TransactionService tx;

  const ScanQrScreen({
    super.key,
    required this.expectedAmount,
    required this.source,
    required this.tx,
  });

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _done = false;

  Color get _primary => const Color(0xFF1ABC9C);
  Color get _success => const Color(0xFF27AE60);

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    try {
      final data = jsonDecode(code);
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      if (amount <= 0) {
        throw Exception('invalid amount');
      }

      // تطبیق با مبلغ واردشده (در صورت واردشدن)
      if (widget.expectedAmount > 0 && amount != widget.expectedAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مبلغ QR با مبلغ ورودی همخوانی ندارد')),
        );
        return;
      }

      final ok = widget.tx.applyPayment(
        amount: amount,
        method: 'qr',
        source: widget.source,
      );
      if (!ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('موجودی کافی نیست')));
        return;
      }

      setState(() => _done = true);

      final r = widget.tx.getLastReceipt();
      if (r != null) {
        final ts = r.timestamp;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _success,
            content: Text(
              'پرداخت موفق: ${r.amount.toInt()} ریال | کد: ${r.id.substring(0,8)} | ${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}',
            ),
          ),
        );
      }
      Navigator.pop(context, true);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('QR نامعتبر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('پرداخت با QR — اسکن'),
        ),
        body: Stack(
          children: [
            MobileScanner(
              onDetect: _onDetect,
              controller: MobileScannerController(
                facing: CameraFacing.back,
                detectionSpeed: DetectionSpeed.noDuplicates,
                torchEnabled: false,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'دوربین را روی QR فروشنده بگیرید',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
