import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  bool _isScanning = true;
  String _status = 'در انتظار اسکن...';
  String? _txid;
  String? _confirmPayload;
  int _amount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePermissions();
    });
  }

  Future<void> _ensurePermissions() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوز دوربین و بلوتوث لازم است.');
      return;
    }
    setState(() => _status = 'آماده برای اسکن QR');
  }

  Future<void> _onScan(String raw) async {
    try {
      final m = jsonDecode(raw) as Map;
      final type = m['type'] ?? '';
      if (type != 'CONFIRM') {
        setState(() => _status = 'فرمت QR معتبر نیست.');
        return;
      }
      _txid = m['txid'];
      _amount = (m['amount'] ?? 0) as int;
      final wallet = m['wallet'] ?? 'main';

      final ok = await LocalDB.instance.receiveAmount(_amount, wallet);
      if (!ok) {
        setState(() => _status = 'دریافت انجام نشد.');
        return;
      }

      setState(() {
        _status = 'تراکنش موفق ثبت شد';
        _confirmPayload = jsonEncode({
          "type": "ACK",
          "txid": _txid,
          "wallet": wallet,
          "amount": _amount,
          "time": DateTime.now().toIso8601String(),
        });
        _isScanning = false;
      });
    } catch (_) {
      setState(() => _status = 'خطا در خواندن QR');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با QR (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isScanning)
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final code = capture.barcodes.first.rawValue;
                    if (code != null && _isScanning) {
                      setState(() => _isScanning = false);
                      _onScan(code);
                    }
                  },
                ),
              )
            else
              const Icon(Icons.qr_code_2, size: 120, color: Colors.green),
            const SizedBox(height: 12),
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            if (_confirmPayload != null)
              Text('کد تأیید: $_confirmPayload',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
