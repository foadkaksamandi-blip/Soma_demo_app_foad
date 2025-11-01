import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  final _amountCtrl = TextEditingController(text: '500000');

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);
    final amount = int.tryParse(_amountCtrl.text.replaceAll('٬','').replaceAll(',','')) ?? 0;
    final payload = jsonEncode({"type":"REQ","amount":amount,"ts":DateTime.now().toIso8601String()});

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تولید QR برای خریدار')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ فروش',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState((){}),
              ),
              const SizedBox(height: 12),
              QrImageView(data: payload, size: 220, backgroundColor: Colors.white),
              const SizedBox(height: 12),
              Text('مبلغ: ${_fmt.format(amount)} ریال'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home),
                label: const Text('بازگشت'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
