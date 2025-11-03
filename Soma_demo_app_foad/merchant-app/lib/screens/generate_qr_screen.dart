import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  String _selectedSource = 'عادی'; // عادی / یارانه / اضطراری / رمز ارز ملی
  String? _qrData;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _generate() {
    final raw = _amountCtrl.text.replaceAll(',', '').trim();
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _showSnack('مبلغ معتبر نیست.');
      return;
    }

    final db = LocalDBMerchant.instance;
    final payload = {
      'amount': amount,
      'source': _selectedSource,
      'merchantId': db.merchantId,
      'ts': DateTime.now().toIso8601String(),
    };

    setState(() {
      _qrData = json.encode(payload);
    });
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: success ? Colors.green : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const sources = ['عادی', 'یارانه', 'اضطراری', 'رمز ارز ملی'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تولید QR برای خریدار'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'مبلغ فروش (ریال)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'مثلاً ۵۰۰٬۰۰۰',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'منبع دریافت',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: sources
                    .map(
                      (s) => ChoiceChip(
                        label: Text(s),
                        selected: _selectedSource == s,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSource = s;
                            });
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('تولید QR'),
              ),
              const SizedBox(height: 24),
              if (_qrData != null) ...[
                Center(
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 220,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'خریدار می‌تواند این QR را اسکن کرده و پرداخت کند.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
