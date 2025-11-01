import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

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
  String? _txId;
  String _status = '';
  String? _confirmPayload;

  @override
  void initState() {
    super.initState();
    // آرگومان‌های ورودی از صفحه قبل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      _wallet = (args['wallet'] ?? 'main') as String;
      _ensureCam();
      setState(() {});
    });
  }

  Future<void> _ensureCam() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) setState(() => _status = 'مجوز دوربین/بلوتوث لازم است');
  }

  Future<void> _onScan(String raw) async {
    try {
      final m = jsonDecode(raw) as Map;
      final want = (m['amount'] ?? 0) as int;
      if (want != _amount) {
        setState(() => _status = 'مبلغ با فاکتور تطبیق ندارد.');
        return;
      }
      final ok = await LocalDB.instance.spend(_amount, wallet: _wallet);
      if (!ok) {
        setState(() => _status = 'موجودی کیف انتخابی کافی نیست.');
        return;
      }
      final tx = LocalDB.instance.newTxId();
      setState(() {
        _txId = tx;
        _status = 'تأییدیه آماده نمایش به فروشنده';
        _confirmPayload = jsonEncode({
          "type": "CONFIRM",
          "txId": tx,
          "amount": _amount,
          "wallet": _wallet,
          "time": DateTime.now().toIso8601String(),
        });
        _showScanner = false;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('مبلغ: ${_fmt.format(_amount)}',
                textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            Text('کیف: $_wallet', textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            Expanded(
              child: _showScanner
                  ? MobileScanner(
                      onDetect: (capture) {
                        final b = capture.barcodes.firstOrNull;
                        final raw = b?.rawValue;
                        if (raw != null) _onScan(raw);
                      },
                    )
                  : Center(
                      child: QrImageView(
                        data: _confirmPayload ?? '',
                        version: QrVersions.auto,
                        size: 240,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(_status,
                style: const TextStyle(fontSize: 16),
                textDirection: TextDirection.rtl),
            if (_txId != null)
              Text('کد تراکنش: $_txId',
                  textDirection: TextDirection.rtl),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _txId),
              child: const Text('تأیید و بازگشت'),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
