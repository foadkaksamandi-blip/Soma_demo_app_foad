import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BuyerHome(),
    );
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});
  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  int mainBalance = 0;
  int subsidy = 50000;
  int emergency = 20000;
  int cbdc = 300000;

  String last = "—";
  String lastTime = "—";

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFF2E7D32);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F2EA),
        elevation: 0,
        title: const Text("اپ آفلاین سوما — اپ خریدار",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _gridBalances(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _btn("پرداخت با بلوتوث", green, () async {
                  final r = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BtPayPage()));
                  if (r is _Txn) {
                    setState(() {
                      mainBalance -= r.amount;
                      last = "TXN-${r.code} / بلوتوث / اصلی";
                      lastTime = r.time;
                    });
                  }
                })),
                const SizedBox(width: 12),
                Expanded(
                    child: _btn("پرداخت با QR", const Color(0xFF9DB5A3), () async {
                  final r = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QrPayPage()));
                  if (r is _Txn) {
                    setState(() {
                      mainBalance -= r.amount;
                      last = "TXN-${r.code} / QR / اصلی";
                      lastTime = r.time;
                    });
                  }
                })),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("آخرین تراکنش",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text("کد: $last"),
                  Text("زمان: $lastTime"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridBalances() => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _card(child: _balance("موجودی اصلی", mainBalance)),
          _card(child: _balance("موجودی یارانه‌ای", subsidy)),
          _card(child: _balance("موجودی اضطراری ملی", emergency)),
          _card(child: _balance("موجودی رمزارز ملی", cbdc)),
        ],
      );

  Widget _balance(String t, int v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("$v",
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCCE2D2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _btn(String t, Color c, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
            backgroundColor: c,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

class _Txn {
  final int amount; final String code; final String time;
  _Txn(this.amount, this.code, this.time);
}

class BtPayPage extends StatefulWidget {
  const BtPayPage({super.key});
  @override
  State<BtPayPage> createState() => _BtPayPageState();
}

class _BtPayPageState extends State<BtPayPage> {
  final TextEditingController amountCtl = TextEditingController(text: "1000");
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connected;

  @override
  void initState() { super.initState(); _scan(); }

  Future<void> _scan() async {
    devices.clear();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    final results = await FlutterBluePlus.scanResults.first;
    setState(() { devices = results.map((e) => e.device).toList(); });
    FlutterBluePlus.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("پرداخت با بلوتوث", style: TextStyle(color: Colors.black)), backgroundColor: const Color(0xFFE8F2EA), iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: amountCtl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "مبلغ خرید", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _scan, child: const Text("اسکن دستگاه‌ها")),
            const SizedBox(height: 8),
            for (final d in devices)
              ListTile(
                title: Text(d.platformName.isEmpty ? d.remoteId.str : d.platformName),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try { await d.connect(timeout: const Duration(seconds: 5)); setState(() => connected = d); } catch (_) {}
                  },
                  child: const Text("اتصال"),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(connected != null ? Icons.lock : Icons.lock_open,
                  color: connected != null ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(connected != null ? "اتصال امن" : "اتصال برقرار نیست"),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: connected != null ? () {
                final amt = int.tryParse(amountCtl.text) ?? 0;
                final now = DateTime.now();
                final code = "${now.millisecondsSinceEpoch % 1000000}";
                Navigator.pop(context, _Txn(amt, code, now.toString().split('.').first));
              } : null,
              child: const Text("پرداخت آفلاین (شبیه‌سازی محلی)"),
            )
          ],
        ),
      ),
    );
  }
}

class QrPayPage extends StatefulWidget {
  const QrPayPage({super.key});
  @override
  State<QrPayPage> createState() => _QrPayPageState();
}

class _QrPayPageState extends State<QrPayPage> {
  final TextEditingController amountCtl = TextEditingController(text: "1000");
  String? scanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("پرداخت با QR", style: TextStyle(color: Colors.black)), backgroundColor: const Color(0xFFE8F2EA), iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: amountCtl, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "مبلغ خرید", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Center(child: QrImageView(data: "AMT:${amountCtl.text}", size: 220)),
            const SizedBox(height: 12),
            Container(
              height: 220, decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
              child: MobileScanner(onDetect: (cap) {
                setState(() => scanned = cap.barcodes.first.rawValue ?? "");
              }),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Icon(scanned != null ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: scanned != null ? Colors.green : Colors.grey),
              const SizedBox(width: 8),
              Text(scanned != null ? "اسکن مقابل تأیید شد" : "منتظر اسکن از فروشنده"),
            ]),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: scanned != null ? () {
                final amt = int.tryParse(amountCtl.text) ?? 0;
                final now = DateTime.now();
                final code = "${now.millisecondsSinceEpoch % 1000000}";
                Navigator.pop(context, _Txn(amt, code, now.toString().split('.').first));
              } : null,
              child: const Text("پرداخت و بازگشت"),
            )
          ],
        ),
      ),
    );
  }
}
