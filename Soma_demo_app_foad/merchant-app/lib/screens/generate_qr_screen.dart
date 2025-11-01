import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// صفحه تولید QR برای نمایش به خریدار
class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key, required this.amount, this.wallet = 'main'});

  /// مبلغی که از صفحه قبل فرستاده می‌شود
  final int amount;

  /// کیف پول انتخابی (main / subsidy / emergency / crypto در دمو)
  final String wallet;

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  late final NumberFormat _fmt;
  late String _payload; // دادهٔ QR
  String _status = '—';
  bool _built = false;

  @override
  void initState() {
    super.initState();
    _fmt = NumberFormat.decimalPattern('fa');
    _buildPayload();
  }

  void _buildPayload() {
    // ساخت درخواست پرداخت برای خریدار
    final data = <String, dynamic>{
      'type': 'REQ',
      'amount': widget.amount,
      'wallet': widget.wallet,
      'time': DateTime.now().toIso8601String(),
    };
    _payload = jsonEncode(data);
    _status = 'QR آماده نمایش است.';
    _built = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نمایش QR به خریدار')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('مبلغ خرید: ${_fmt.format(widget.amount)}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('کیف پول: ${widget.wallet}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            if (_built)
              Expanded(
                child: Center(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QrImageView(
                        data: _payload,
                        version: QrVersions.auto,
                        size: 280,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('وضعیت: $_status'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _buildPayload,
              child: const Text('بازتولید QR'),
            ),
          ],
        ),
      ),
    );
  }
}
