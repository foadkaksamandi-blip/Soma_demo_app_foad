import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/transaction_service.dart';
import '../services/local_db.dart';
import '../models/tx_log.dart';

class QrPayScreen extends StatefulWidget {
  const QrPayScreen({super.key});

  @override
  State<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends State<QrPayScreen> {
  bool _scanned = false;
  String? _last;
  String _source = 'عادی';

  void _onDetect(BarcodeCapture cap) {
    if (_scanned) return;
    final raw = cap.barcodes.first.rawValue ?? '';
    if (!raw.startsWith('SOMA')) return;

    _scanned = true;
    _last = raw;

    final data = TransactionService.parseInboundPayload(raw);
    final amount = int.tryParse(data['AMOUNT'] ?? '0') ?? 0;
    final src = data['SOURCE'] ?? 'عادی';

    if (amount > 0) {
      LocalDB.instance.addToWallet(src, -amount);
      final log = TxLog.success(
        amount: amount,
        source: src,
        method: 'QR',
        counterparty: 'merchant',
      );
      final confirm = TransactionService.buildMerchantConfirm(log: log);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('پرداخت ${amount} ریال از $_source انجام شد.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _last = confirm);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color successGreen = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          title: const Text('پرداخت با QR کد'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(onDetect: _onDetect),
            ),
            if (_last != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  _last!,
                  textDirection: TextDirection.ltr,
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
