import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../services/local_db.dart';
import '../services/transaction_service.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _processing = false;
  String? _lastCode;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _onQRViewCreated(QRViewController c) async {
    controller = c;
    controller?.scannedDataStream.listen((scanData) async {
      if (_processing) return;
      final code = scanData.code;
      if (code == null) return;
      if (code == _lastCode) return;

      setState(() {
        _processing = true;
        _lastCode = code;
      });

      try {
        await _handleScannedCode(code);
      } finally {
        if (mounted) {
          setState(() {
            _processing = false;
          });
        }
      }
    });
  }

  Future<void> _handleScannedCode(String code) async {
    Map<String, dynamic> data;
    try {
      data = json.decode(code) as Map<String, dynamic>;
    } catch (_) {
      _showSnack('کد QR نامعتبر است.');
      return;
    }

    final amount = data['amount'] is int
        ? data['amount'] as int
        : int.tryParse(data['amount']?.toString() ?? '0') ?? 0;
    if (amount <= 0) {
      _showSnack('مبلغ در QR معتبر نیست.');
      return;
    }

    final db = LocalDBMerchant.instance;
    await TransactionServiceMerchant.instance
        .applyQrReceive(db: db, amount: amount);

    _showSnack('دریافت مبلغ با QR انجام شد.', success: true);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: success ? Colors.green : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اسکن QR از خریدار'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 4,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
            const Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  'دوربین را روی QR خریدار نگه دارید.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
