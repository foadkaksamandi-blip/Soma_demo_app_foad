import 'package:flutter/material.dart';

void main() => runApp(const SomaMerchantApp());

class SomaMerchantApp extends StatelessWidget {
  const SomaMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Offline — Merchant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const MerchantHomePage(),
    );
  }
}

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  final TextEditingController _receivedCtrl = TextEditingController(text: "0");
  final TextEditingController _lastTxCtrl = TextEditingController();

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _simulateReceive(String via) {
    final nowId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _lastTxCtrl.text = nowId;
      final current = int.tryParse(_receivedCtrl.text) ?? 0;
      _receivedCtrl.text = (current + 1).toString();
    });
    _toast("دریافت تراکنش (Placeholder) از مسیر $via");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اپ آفلاین سوما — اپ فروشنده"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(flex: 2, child: Text("تعداد دریافتی‌ها")),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _receivedCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 2, child: Text("آخرین شناسه تراکنش")),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _lastTxCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: "ID",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _simulateReceive("Bluetooth"),
                  child: const Text("دریافت از بلوتوث"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _simulateReceive("QR"),
                  child: const Text("دریافت از QR"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
