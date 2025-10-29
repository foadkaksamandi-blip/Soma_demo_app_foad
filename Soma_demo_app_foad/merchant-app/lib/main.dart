import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/transaction_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Offline SOMA — Merchant',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF4ECDC4)),
      home: const MerchantHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});
  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  final _svc = MerchantService();
  final _amountCtl = TextEditingController();
  final _qrCtl = TextEditingController();
  String _method = 'bluetooth';
  String? _lastLog;

  String _fmt(num v) => NumberFormat.decimalPattern('fa').format(v);

  @override
  void dispose() {
    _amountCtl.dispose();
    _qrCtl.dispose();
    super.dispose();
  }

  Future<void> _acceptViaQr() async {
    final txt = _qrCtl.text.trim();
    if (txt.isEmpty) return;
    try {
      final map = json.decode(txt) as Map<String, dynamic>;
      final amt = (map['amount'] as num).toDouble();
      final ok = _svc.acceptPayment(amount: amt, method: 'qr');
      setState(() => _lastLog = ok ? 'قبول شد: $_{
          _fmt(amt)
        }' : 'رد شد (موجودی خریدار ناکافی)');
      final snack = ScaffoldMessenger.of(context);
      snack.showSnackBar(SnackBar(content: Text(_lastLog!)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR نامعتبر')));
    }
  }

  Future<void> _acceptManual() async {
    final amt = double.tryParse(_amountCtl.text.trim()) ?? 0;
    final ok = _svc.acceptPayment(amount: amt, method: _method);
    final snack = ScaffoldMessenger.of(context);
    setState(() => _lastLog = ok ? 'قبول شد: ${_fmt(amt)}' : 'رد شد');
    snack.showSnackBar(SnackBar(content: Text(_lastLog!)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اپ آفلاین سوما — اپ فروشنده'),
        backgroundColor: cs.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text('موجودی صندوق: ${_fmt(_svc.merchantBalance)}'), backgroundColor: cs.secondaryContainer),
          ]),
          const SizedBox(height: 16),

          TextField(
            controller: _amountCtl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'مبلغ دستی (اختیاری)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: RadioListTile(value: 'bluetooth', groupValue: _method, onChanged: (v) => setState(() => _method = '$v'), title: const Text('Bluetooth'))),
            Expanded(child: RadioListTile(value: 'qr', groupValue: _method, onChanged: (v) => setState(() => _method = '$v'), title: const Text('QR Code'))),
          ]),
          const SizedBox(height: 12),

          FilledButton.icon(onPressed: _acceptManual, icon: const Icon(Icons.offline_pin), label: const Text('دریافت آفلاین')),
          const SizedBox(height: 16),

          const Divider(),

          const Text('پیست کردن QR دریافتی از خریدار'),
          const SizedBox(height: 8),
          TextField(
            controller: _qrCtl,
            maxLines: 4,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'متن QR را اینجا بچسبانید'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _acceptViaQr, icon: const Icon(Icons.qr_code_2), label: const Text('تأیید از QR')),
          const SizedBox(height: 16),

          if (_svc.lastReceipt != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt),
                title: Text('آخرین تراکنش: ${_fmt(_svc.lastReceipt!.amount)}'),
                subtitle: Text('روش: ${_svc.lastReceipt!.method} • زمان: ${_svc.lastReceipt!.timestamp.toLocal()}'),
              ),
            ),
          if (_lastLog != null) Text(_lastLog!, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
