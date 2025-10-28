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
  String? _last;

  void _onDetect(BarcodeCapture cap) {
    final raw = cap.barcodes.first.rawValue ?? '';
    if (!raw.startsWith('SOMA|')) return;

    final data = TransactionService.parseInboundPayload(raw);
    final amount = int.tryParse(data['AMOUNT'] ?? '0') ?? 0;
    final src = data['SOURCE'] ?? 'نامشخص';

    LocalDb.instance.addToWallet(src, amount);

    final log = TxLog.success(
      amount: amount,
      source: src,
      method: 'qr',
      counterparty: 'merchant',
    );

    final confirm = TransactionService.buildMerchantConfirm(log: log);
    setState(() => _last = confirm);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('پرداخت QR شناسایی و ذخیره شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2FAE60),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('اسکن QR برای پرداخت'),
        ),
        body: Column(
          children: [
            Expanded(child: MobileScanner(onDetect: _onDetect)),
            if (_last != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(_last!),
              ),
          ],
        ),
      ),
    );
  }
}
