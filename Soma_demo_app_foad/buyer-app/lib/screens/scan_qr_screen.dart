import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/transaction_service.dart';
import '../services/local_db.dart';
import '../models/tx_log.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _handled = false;
  String _source = 'عادی';
  String? _confirmPayload;
  TxLog? _lastLog;

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue ?? '' : '';
    if (!raw.startsWith('SOMA')) return;

    _handled = true;

    final data = TransactionService.parseInboundPayload(raw);
    final amount = int.tryParse(data['AMOUNT'] ?? '0') ?? 0;
    final src = data['SOURCE'] ?? _source;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ معتبر در QR یافت نشد.')),
      );
      return;
    }

    LocalDB.instance.addToWallet(src, -amount);

    final log = TxLog.success(
      amount: amount,
      source: src,
      method: 'QR',
      counterparty: 'merchant',
    );

    final confirm = TransactionService.buildBuyerConfirmQr(log);

    setState(() {
      _source = src;
      _lastLog = log;
      _confirmPayload = confirm;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('پرداخت ${amount} ریال از «$src» انجام شد. QR تایید را به فروشنده نشان دهید.'),
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
          title: const Text('پرداخت با QR کد'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(child: MobileScanner(onDetect: _onDetect)),
            if (_confirmPayload != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('QR تایید خریدار — برای اسکن فروشنده'),
                    const SizedBox(height: 8),
                    QrImageView(
                      data: _confirmPayload!,
                      size: 220,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      gapless: true,
                    ),
                    const SizedBox(height: 8),
                    if (_lastLog != null)
                      Text('کد تراکنش: ${_lastLog!.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
