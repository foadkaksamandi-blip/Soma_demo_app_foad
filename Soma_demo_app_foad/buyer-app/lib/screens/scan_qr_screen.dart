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
  bool _processing = false;
  String? _lastCode;
  String _selectedSource = 'عادی'; // عادی / یارانه / اضطراری / رمز ارز ملی

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
    // انتظار داریم QR شامل JSON باشد: { "amount": 500000, "mode": "normal|subsidy|emergency|cbdc" }
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

    // بررسی موجودی بر اساس منبع انتخاب شده
    final db = LocalDB.instance;
    int currentBalance;
    switch (_selectedSource) {
      case 'یارانه':
        currentBalance = db.buyerSubsidyBalance;
        break;
      case 'اضطراری':
        currentBalance = db.buyerEmergencyBalance;
        break;
      case 'رمز ارز ملی':
        currentBalance = db.buyerCbdcBalance;
        break;
      default:
        currentBalance = db.buyerBalance;
    }

    if (currentBalance < amount) {
      _showSnack('موجودی کافی نیست.');
      return;
    }

    // کسر از موجودی منبع انتخاب‌شده، افزایش موجودی فروشنده و ثبت لاگ
    db.applyQrPaymentFromSource(
      source: _selectedSource,
      amount: amount,
    );

    await TransactionHistoryService.instance.logBuyerQrPayment(
      amount: amount,
      source: _selectedSource,
      merchantId: data['merchantId']?.toString() ?? 'merchant-unknown',
    );

    _showSnack('پرداخت QR با موفقیت انجام شد.', success: true);
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
    const sources = ['عادی', 'یارانه', 'اضطراری', 'رمز ارز ملی'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پرداخت با QR کد'),
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
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'منبع پرداخت را انتخاب کنید',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: sources
                          .map(
                            (s) => ChoiceChip(
                              label: Text(s),
                              selected: _selectedSource == s,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedSource = s;
                                  });
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_processing) ...[
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ] else ...[
                      const Text(
                        'دوربین روی QR فروشنده نگه داشته شود.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
