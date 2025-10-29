import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/transaction_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Offline SOMA — Buyer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C63FF)),
      home: const BuyerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});
  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final _svc = TransactionService();
  final _amountCtl = TextEditingController();
  String _method = 'bluetooth';
  String _source = 'balance';
  String? _lastQr;

  String _fmt(num v) => NumberFormat.decimalPattern('fa').format(v);

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _genQr() async {
    final amount = double.tryParse(_amountCtl.text.trim()) ?? 0;
    final payload = _svc.generateQrPayload(amount);
    setState(() => _lastQr = payload);
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtl.text.trim()) ?? 0;
    final ok = _svc.applyPayment(
      amount: amount,
      method: _method,
      source: _source,
    );
    if (!mounted) return;
    final snack = ScaffoldMessenger.of(context);
    if (ok) {
      snack.showSnackBar(const SnackBar(content: Text('تراکنش آفلاین با موفقیت ثبت شد ✅')));
      setState(() {});
    } else {
      snack.showSnackBar(const SnackBar(content: Text('❌ مبلغ نامعتبر یا موجودی کافی نیست')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اپ آفلاین سوما — اپ خریدار'),
        backgroundColor: cs.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // خط موجودی‌ها
          Wrap(spacing: 8, runSpacing: 8, children: [
            _balanceChip('موجودی  یارانه', _fmt(_svc.subsidyBalance), cs),
            _balanceChip('موجودی اضطراری ملی', _fmt(_svc.emergencyBalance), cs),
            _balanceChip('موجودی کیف پول رمز ارز ملی', _fmt(_svc.cryptoBalance), cs),
          ]),
          const SizedBox(height: 16),

          // روش پرداخت
          _sectionTitle('روش اتصال پرداخت'),
          Row(children: [
            Expanded(
              child: RadioListTile(
                value: 'bluetooth',
                groupValue: _method,
                onChanged: (v) => setState(() => _method = '$v'),
                title: const Text('Bluetooth'),
              ),
            ),
            Expanded(
              child: RadioListTile(
                value: 'qr',
                groupValue: _method,
                onChanged: (v) => setState(() => _method = '$v'),
                title: const Text('QR Code'),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // منبع وجه
          _sectionTitle('منبع وجه'),
          DropdownButtonFormField<String>(
            value: _source,
            items: const [
              DropdownMenuItem(value: 'balance', child: Text('کیف پول نقدی')),
              DropdownMenuItem(value: 'subsidy', child: Text('یارانه')),
              DropdownMenuItem(value: 'emergency', child: Text('اضطراری ملی')),
              DropdownMenuItem(value: 'crypto', child: Text('رمز ارز ملی')),
            ],
            onChanged: (v) => setState(() => _source = v!),
          ),
          const SizedBox(height: 12),

          // مبلغ
          _sectionTitle('مبلغ خرید'),
          TextField(
            controller: _amountCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'مبلغ را عددی وارد کنید',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // دکمه‌ها
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _pay,
                icon: const Icon(Icons.offline_bolt),
                label: const Text('ثبت تراکنش آفلاین'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _genQr,
                icon: const Icon(Icons.qr_code),
                label: const Text('تولید QR برای فروشنده'),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          if (_lastQr != null) _qrPreview(_lastQr!, cs),

          const Divider(height: 32),

          // رسید آخر
          _sectionTitle('آخرین رسید'),
          _lastReceiptCard(),
        ]),
      ),
    );
  }

  Widget _balanceChip(String title, String value, ColorScheme cs) {
    return Chip(
      label: Text('$title: $value'),
      backgroundColor: cs.secondaryContainer,
    );
  }

  Widget _sectionTitle(String t) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)));

  Widget _qrPreview(String payload, ColorScheme cs) {
    // نمایش متن QR (برای دمو؛ در نسخه‌ی بعدی تصویر QR واقعی هم اضافه می‌کنیم)
    final pretty = const JsonEncoder.withIndent('  ').convert(json.decode(payload));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(pretty, textDirection: TextDirection.ltr),
    );
  }

  Widget _lastReceiptCard() {
    final r = _svc.lastReceipt;
    if (r == null) return const Text('—');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text('مبلغ: ${_fmt(r.amount)}  |  روش: ${r.method}'),
        subtitle: Text('منبع: ${r.source}  •  زمان: ${r.timestamp.toLocal()}'),
        dense: true,
      ),
    );
  }
}
