// merchant-app/lib/screens/scan_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/transaction_service.dart';
import '../models/tx_log.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handled = false;
  int _expectedAmount = 0;
  String _source = 'یارانه';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _expectedAmount = (args['expectedAmount'] as int?) ?? 0;
    _source = (args['source'] as String?) ?? 'یارانه';
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    _handled = true;
    final raw = codes.first.rawValue ?? '';
    final map = TransactionService.parseInboundPayload(raw);

    // اگر خریدار QR تایید فرستاده بود (CONFIRM=OK) یا درخواست مبلغ بود (ROLE=BUYER/ MERCHANT)
    final claimedAmount = int.tryParse(map['AMOUNT'] ?? '0') ?? 0;
    final src = map['SOURCE'] ?? _source;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأیید دریافت'),
        content: Text(
          'مبلغ: ${claimedAmount > 0 ? claimedAmount : _expectedAmount} ریال\n'
          'منبع: $src\n'
          'آیا این دریافت ثبت شود؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = claimedAmount > 0 ? claimedAmount : _expectedAmount;
              final log = TransactionService.applyMerchantCredit(
                amount: amount,
                source: src,
                method: 'QR',
              );
              final confirm = TransactionService.buildMerchantConfirm(log: log);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'دریافت ثبت شد. کد تراکنش: ${log.id}',
                    textDirection: TextDirection.rtl,
                  ),
                  backgroundColor: const Color(0xFF27AE60),
                ),
              );

              // (اختیاری) نمایش QR یا متن تأیید برای خریدار
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('تأیید فروشنده'),
                  content: Text(
                    confirm,
                    textDirection: TextDirection.ltr,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('بستن'),
                    ),
                  ],
                ),
              );

              Navigator.pop(context);
            },
            child: const Text('ثبت دریافت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        title: const Text('اسکن QR (فروشنده)'),
        centerTitle: true,
      ),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
