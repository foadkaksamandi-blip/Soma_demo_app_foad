// merchant-app/lib/screens/scan_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/local_db.dart';
import '../services/transaction_service.dart';
import '../models/tx_log.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handled = false;
  TxLog? _log;

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue ?? '' : '';
    if (!raw.startsWith('SOMA')) return;

    final m = TransactionService.parseInboundPayload(raw);
    if ((m['TYPE'] ?? '') != 'CONFIRM') return;

    final log = TxLog.fromMap(m);
    if (log.amount <= 0) return;

    _handled = true;
    LocalDBMerchant.instance.addMerchantBalance(log.amount);

    setState(() => _log = log);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('دریافت ${log.amount} ریال ثبت شد. کد: ${log.id}',
            textDirection: TextDirection.rtl),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          title: const Text('اسکن تایید خریدار'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(child: MobileScanner(onDetect: _onDetect)),
            if (_log != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('کد تراکنش: ${_log!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('مبلغ: ${_log!.amount} ریال'),
                    Text('کیف: ${_log!.source} — روش: ${_log!.method}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
