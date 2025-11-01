import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/local_db.dart';
import '../services/permissions.dart';

/// صفحه اسکن QR فروشنده و انجام پرداخت آفلاین
class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final NumberFormat _fmt = NumberFormat.decimalPattern('fa');

  final MobileScannerController _controller = MobileScannerController();
  bool _showScanner = true;
  bool _handled = false;

  String _status = 'در انتظار اسکن…';
  String? _txId;
  int? _amount;
  String _wallet = 'main';
  String? _confirmPayload;

  @override
  void initState() {
    super.initState();
    // اجازه‌ها (دوربین)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await AppPermissions.ensureBTAndCamera();
      if (!ok && mounted) setState(() => _status = 'مجوز دوربین لازم است.');
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return; // فقط اولین اسکن
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;

    _handled = true;
    try {
      final m = jsonDecode(code) as Map<String, dynamic>;
      if ((m['type'] as String?) != 'REQ') {
        setState(() => _status = 'QR نامعتبر است.');
        return;
      }

      final amount = (m['amount'] as num?)?.toInt() ?? 0;
      final wallet = (m['wallet'] as String?) ?? 'main';

      if (amount <= 0) {
        setState(() => _status = 'مبلغ معتبر نیست.');
        return;
      }

      // کسر مبلغ از کیف انتخابی
      final ok = await LocalDB.instance.spend_amount(amount, wallet);
      if (!ok) {
        setState(() => _status = 'موجودی کیف انتخابی کافی نیست.');
        return;
      }

      // ثبت تراکنش محلی
      final tx = await LocalDB.instance.newTxId();

      setState(() {
        _amount = amount;
        _wallet = wallet;
        _txId = tx;
        _showScanner = false;
        _status = 'پرداخت انجام شد.';
        _confirmPayload = jsonEncode({
          'type': 'CONFIRM',
          'txid': tx,
          'amount': amount,
          'wallet': wallet,
          'time': DateTime.now().toIso8601String(),
        });
      });
    } catch (_) {
      setState(() => _status = 'خطا در خواندن QR.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showScanner)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('نتیجه پرداخت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('مبلغ: ${_fmt.format(_amount ?? 0)}'),
                        Text('کیف پول: $_wallet'),
                        Text('کد تراکنش: ${_txId ?? '—'}'),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text('Payload تأیید (برای فروشنده):'),
                        const SizedBox(height: 6),
                        SelectableText(_confirmPayload ?? '—'),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('وضعیت: $_status'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _handled = false;
                        _showScanner = true;
                        _status = 'در انتظار اسکن…';
                      });
                    },
                    child: const Text('اسکن دوباره'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
