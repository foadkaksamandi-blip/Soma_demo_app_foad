import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/local_db.dart';
import '../services/permissions.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  final TextEditingController _amountCtrl = TextEditingController();
  String _wallet = 'main';

  String? _payload; // QR پرداخت برای خریدار
  bool _waitingConfirm = false;
  String? _status;
  MobileScannerController? _scanner;

  @override
  void dispose() {
    _scanner?.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _makeQr() async {
    final a = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (a <= 0) {
      setState(() => _status = 'مبلغ نامعتبر است.');
      return;
    }
    final data = {
      "type": "PAYMENT_REQUEST",
      "amount": a,
      "wallet": _wallet,
      "merchant": "SOMA-DEMO-MERCHANT",
      "time": DateTime.now().toIso8601String(),
    };
    setState(() {
      _payload = jsonEncode(data);
      _status = 'QR تولید شد. از خریدار بخواهید اسکن کند.';
      _waitingConfirm = true;
    });
  }

  Future<void> _scanConfirm() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) return;

    _scanner ??= MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('اسکن تأیید خریدار'),
              const SizedBox(height: 12),
              Expanded(
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: (cap) async {
                    try {
                      if (cap.barcodes.isEmpty) return;
                      final raw = cap.barcodes.first.rawValue;
                      if (raw == null || raw.isEmpty) return;

                      final m = jsonDecode(raw) as Map;
                      if (m['type'] != 'CONFIRM') return;

                      final amount = (m['amount'] ?? 0) as int;
                      final wallet = (m['wallet'] ?? 'main') as String;
                      final txId = (m['txId'] ?? '') as String;

                      await LocalDBMerchant.instance.addIncome(wallet: wallet, amount: amount);

                      if (!mounted) return;
                      setState(() {
                        _status = 'تراکنش موفق. کد: $txId';
                        _waitingConfirm = false;
                      });
                      Navigator.pop(context);
                    } catch (_) {}
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color successGreen = Color(0xFF27AE60);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دریافت با QR')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('اصلی'), selected: _wallet == 'main', onSelected: (_) => setState(() => _wallet = 'main')),
                ChoiceChip(label: const Text('یارانه‌ای'), selected: _wallet == 'subsidy', onSelected: (_) => setState(() => _wallet = 'subsidy')),
                ChoiceChip(label: const Text('اضطراری ملی'), selected: _wallet == 'emergency', onSelected: (_) => setState(() => _wallet = 'emergency')),
                ChoiceChip(label: const Text('رمزارز ملی'), selected: _wallet == 'crypto', onSelected: (_) => setState(() => _wallet = 'crypto')),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ فروش (ریال)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _makeQr, child: const Text('تولید QR برای خریدار')),
              const SizedBox(height: 12),
              if (_payload != null)
                Center(
                  child: QrImageView(
                    data: _payload!,
                    size: 220,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                ),
              const SizedBox(height: 12),
              if (_waitingConfirm)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white),
                  onPressed: _scanConfirm,
                  child: const Text('اسکن تأیید خریدار و نهایی‌سازی'),
                ),
              if (_status != null) ...[
                const SizedBox(height: 8),
                Text(_status!, style: const TextStyle(color: Colors.black87)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
