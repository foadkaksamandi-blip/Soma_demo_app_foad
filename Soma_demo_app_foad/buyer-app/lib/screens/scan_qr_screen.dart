import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class ScanQrScreen extends StatefulWidget {
  final int amount;
  const ScanQrScreen({super.key, required this.amount});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _showScanner = true;
  String _status = 'در حال آماده‌سازی برای اسکن...';

  @override
  void initState() {
    super.initState();
    _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوز دوربین یا بلوتوث لازم است.');
      return;
    }
    setState(() => _status = 'آماده برای اسکن QR.');
  }

  Future<void> _onScan(BarcodeCapture capture) async {
    try {
      final raw = capture.barcodes.first.rawValue;
      if (raw == null) return;
      final m = jsonDecode(raw) as Map;
      final amount = (m['amount'] ?? 0) as int;
      final wallet = m['wallet'] ?? 'main';

      final ok = await LocalDB.instance.spend_amount(amount, wallet);
      if (ok) {
        setState(() {
          _status = 'پرداخت $amount تومان انجام شد ✅';
          _showScanner = false;
        });
      } else {
        setState(() => _status = 'موجودی کافی نیست ❌');
      }
    } catch (e) {
      setState(() => _status = 'QR نامعتبر است.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پرداخت با QR (آفلاین)')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_status, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Expanded(
                child: _showScanner
                    ? MobileScanner(
                        onDetect: _onScan,
                        allowDuplicates: false,
                      )
                    : const Center(
                        child: Icon(Icons.check_circle,
                            color: Colors.green, size: 120),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
