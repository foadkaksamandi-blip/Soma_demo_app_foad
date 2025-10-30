import 'package:flutter/material.dart';

void main() => runApp(const SomaBuyerApp());

class SomaBuyerApp extends StatelessWidget {
  const SomaBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Offline — Buyer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const BuyerHomePage(),
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final TextEditingController _balanceCtrl =
      TextEditingController(text: "100000"); // موجودی اولیه نمونه
  final TextEditingController _amountCtrl = TextEditingController(text: "0");
  final TextEditingController _offlineTxCtrl = TextEditingController(text: "");

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  int _asInt(TextEditingController c) {
    final v = int.tryParse(c.text.replaceAll(",", "").trim());
    return v ?? 0;
  }

  void _doPayOffline() {
    final bal = _asInt(_balanceCtrl);
    final amt = _asInt(_amountCtrl);
    if (amt <= 0) {
      _toast("مبلغ نامعتبر است.");
      return;
    }
    if (bal < amt) {
      _toast("موجودی کافی نیست.");
      return;
    }
    final newBal = bal - amt;
    setState(() {
      _balanceCtrl.text = newBal.toString();
      _offlineTxCtrl.text = DateTime.now().millisecondsSinceEpoch.toString();
    });
    _toast("تراکنش آفلاین شبیه‌سازی شد (کاهش موجودی محلی).");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("اپ آفلاین سوما — اپ خریدار"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // موجودی
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text("موجودی", textAlign: TextAlign.start),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _balanceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "عدد موجودی",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // روش‌ها (Bluetooth / QR)
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: () => _toast("اسکن بلوتوث (Placeholder)"),
                      child: const Text("اسکن بلوتوث"),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 6),
                        Text("اتصال امن"),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(Icons.privacy_tip_outlined, size: 18),
                        SizedBox(width: 6),
                        Text("عدم شناسایی"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.tonal(
                      onPressed: () => _toast("اسکن QR (Placeholder)"),
                      child: const Text("QR کد"),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.lock_outline, size: 18),
                        SizedBox(width: 6),
                        Text("اتصال امن"),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(Icons.privacy_tip_outlined, size: 18),
                        SizedBox(width: 6),
                        Text("عدم شناسایی"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),

          // مبلغ خرید
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text("مبلغ خرید"),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "عدد مبلغ",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // تراکنش آفلاین (نمایش)
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text("تراکنش آفلاین"),
              ),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _offlineTxCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: "شناسه/رسید",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // دکمه پرداخت
          FilledButton(
            onPressed: _doPayOffline,
            child: const Text("پرداخت آفلاین (شبیه‌سازی محلی)"),
          ),
        ],
      ),
    );
  }
}
