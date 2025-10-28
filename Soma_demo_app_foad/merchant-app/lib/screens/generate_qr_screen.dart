// merchant-app/lib/screens/generate_qr_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/transaction_service.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  final _nf = NumberFormat.decimalPattern('fa');
  String _source = 'یارانه';
  String? _payload;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          title: const Text('تولید QR (درخواست مبلغ)'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('مبلغ دریافت (ریال)'),
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
            const SizedBox(height: 12),
            const Text('منبع پرداخت'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('یارانه'),
                  selected: _source == 'یارانه',
                  onSelected: (_) => setState(() => _source = 'یارانه'),
                ),
                ChoiceChip(
                  label: const Text('اضطراری'),
                  selected: _source == 'اضطراری',
                  onSelected: (_) => setState(() => _source = 'اضطراری'),
                ),
                ChoiceChip(
                  label: const Text('رمز ارز ملی'),
                  selected: _source == 'رمز ارز ملی',
                  onSelected: (_) => setState(() => _source = 'رمز ارز ملی'),
                ),
                ChoiceChip(
                  label: const Text('عادی'),
                  selected: _source == 'عادی',
                  onSelected: (_) => setState(() => _source = 'عادی'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('تولید QR درخواست'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryTurquoise),
              onPressed: () {
                final amt = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                if (amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لطفاً مبلغ معتبر وارد کنید.')),
                  );
                  return;
                }
                final p = TransactionService.buildRequestPayload(amount: amt, source: _source);
                setState(() => _payload = p);
              },
            ),
            const SizedBox(height: 24),
            if (_payload != null) ...[
              Center(
                child: QrImageView(
                  data: _payload!,
                  size: 220,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  gapless: true,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _payload!,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'خریدار باید این QR را اسکن کند. پس از پرداخت موفق، QR تایید نمایش داده می‌شود تا شما اسکن/ثبت کنید.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
