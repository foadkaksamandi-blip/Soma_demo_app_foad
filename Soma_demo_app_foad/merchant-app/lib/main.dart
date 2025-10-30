import 'dart:ui' as ui; // برای TextDirection
import 'package:flutter/material.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      home: const MerchantHome(),
    );
  }
}

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});

  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  final TextEditingController balanceCtrl = TextEditingController(text: '0');
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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اپ آفلاین سوما — اپ فروشنده'),
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
                    readOnly: true,
                    decoration: const InputDecoration(hintText: 'موجودی فروشنده'),
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
                    onPressed: _onBluetoothListen,
                    child: const Text('اسکن بلوتوث'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onShowQr,
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
              onPressed: _onSettle,
              icon: const Icon(Icons.download_done),
              label: const Text('تسویه آفلاین'),
            ),
          ],
        ),
      ),
    );
  }

  void _onBluetoothListen() {
    _snack('(دمو) حالت پذیرنده بلوتوث فعال شد');
  }

  void _onShowQr() {
    _snack('(دمو) نمایش QR برای دریافت');
  }

  void _onSettle() {
    final bal = int.tryParse(balanceCtrl.text.replaceAll(',', '')) ?? 0;
    final amt = int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amt <= 0) return _snack('مبلغ نامعتبر');
    final newBal = bal + amt;
    setState(() => balanceCtrl.text = newBal.toString());
    _snack('تسویه آفلاین ثبت شد ✔');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
