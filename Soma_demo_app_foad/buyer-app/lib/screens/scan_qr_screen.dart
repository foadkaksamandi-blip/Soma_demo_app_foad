import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  late int _amount;
  late String _wallet;

  bool _showScanner = true;
  String? _txid;
  String _status = '';
  String? _confirmPayload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      _wallet = (args['wallet'] ?? 'main') as String;
      setState(() {});
    });
  }

  Future<void> _ensureCam() async {
    // دوربین فقط: مجوزها را MobileScanner خودش درخواست می‌کند
    setState(() => _status = 'دوربین آماده اسکن است');
  }

  Future<void> _onScan(BarcodeCapture cap) async {
    try {
      final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
      if (raw == null) return;
      final m = jsonDecode(raw) as Map;
      final want = (m['amount'] ?? 0) as int;
      if (want != _amount) {
        setState(() => _status = 'مبلغ با فاکتور تطبیق ندارد.');
        return;
      }
      final ok = await LocalDB.instance.spend_amount(_amount, _wallet);
      if (!ok) {
        setState(() => _status = 'موجودی کیف انتخابی کافی نیست.');
        return;
      }
      final tx = await LocalDB.instance.newTxId();
      setState(() {
        _txid = tx;
        _confirmPayload = jsonEncode({
          "type": "CONFIRM",
          "txid": tx,
          "amount": _amount,
          "wallet": _wallet,
          "time": DateTime.now().toIso8601String(),
        });
        _showScanner = false;
        _status = 'تراکنش تایید شد';
      });
    } catch (_) {
      setState(() => _status = 'QR نامعتبر است');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت QR (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('اصلی'), selected: _wallet=='main', onSelected: (_) => setState(()=>_wallet='main')),
                ChoiceChip(label: const Text('یارانه‌ای'), selected: _wallet=='subsidy', onSelected: (_) => setState(()=>_wallet='subsidy')),
                ChoiceChip(label: const Text('اضطراری ملی'), selected: _wallet=='emergency', onSelected: (_) => setState(()=>_wallet='emergency')),
                ChoiceChip(label: const Text('رمزارز ملی'), selected: _wallet=='crypto', onSelected: (_) => setState(()=>_wallet='crypto')),
              ],
            ),
            const SizedBox(height: 12),
            Text('مبلغ خرید: ${_fmt.format(_amount)}'),
            const SizedBox(height: 12),
            if (_showScanner) ...[
              ElevatedButton(
                onPressed: _ensureCam,
                child: const Text('تولید و اسکن QR'),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.normal, // بدون allowDuplicates
                  ),
                  onDetect: _onScan,
                ),
              ),
            ] else ...[
              const Text('برای نمایش به فروشنده – کُد تایید'),
              const SizedBox(height: 8),
              if (_confirmPayload != null)
                QrImageView(data: _confirmPayload!, size: 220),
              const SizedBox(height: 8),
              Text('کد تراکنش: ${_txid ?? "-"}'),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {'ok': true, 'txid': _txid}),
                child: const Text('تأیید و بازگشت'),
              ),
            ],
            const SizedBox(height: 12),
            Text(_status, textDirection: TextDirection.rtl),
          ],
        ),
      ),
    );
  }
}
