import 'dart:ui' as ui; // برای TextDirection.{ltr,rtl}
import 'package:flutter/material.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const BuyerHome(),
    );
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  final TextEditingController balanceCtrl = TextEditingController(text: '2500000');
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController offlineTxCtrl = TextEditingController();
  bool secureConnect = true;
  bool anonymous = false;

  @override
  void dispose() {
    balanceCtrl.dispose();
    amountCtrl.dispose();
    offlineTxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality( // حل قطعی خطای TextDirection
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اپ آفلاین سوما — اپ خریدار'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('موجودی:'),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: balanceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'عدد موجودی'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: secureConnect,
                    onChanged: (v) => setState(() => secureConnect = v ?? false),
                    title: const Text('اتصال امن'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: anonymous,
                    onChanged: (v) => setState(() => anonymous = v ?? false),
                    title: const Text('عدم شناسایی'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onScanBluetooth,
                    child: const Text('اسکن بلوتوث'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onScanQr,
                    child: const Text('QR کد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('مبلغ خرید:'),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'مبلغ به ریال'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('تراکنش آفلاین:'),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: offlineTxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'شناسه/شماره'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _onPay,
              icon: const Icon(Icons.check),
              label: const Text('پرداخت آفلاین'),
            ),
          ],
        ),
      ),
    );
  }

  void _onScanBluetooth() {
    _snack('(دمو) اسکن بلوتوث — بدون وابستگی سخت‌افزاری');
  }

  void _onScanQr() {
    _snack('(دمو) اسکن QR — بدون دوربین');
  }

  void _onPay() {
    final bal = int.tryParse(balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final amt = int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amt <= 0) return _snack('مبلغ نامعتبر');
    if (bal < amt) return _snack('موجودی کافی نیست');
    final newBal = bal - amt;
    setState(() => balanceCtrl.text = newBal.toString());
    _snack('پرداخت آفلاین ثبت شد ✔');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
