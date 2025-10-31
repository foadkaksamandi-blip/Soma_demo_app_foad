import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() => runApp(const MerchantApp());

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MerchantHome(),
    );
  }
}

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});
  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  int balance = 100000;
  String lastCode = "—";
  String lastTime = "—";

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF2E7D32);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F2EA),
        elevation: 0,
        centerTitle: false,
        title: const Text("اپ آفلاین سوما — اپ فروشنده",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("موجودی",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text("$balance",
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: "دریافت از بلوتوث",
                    enabled: true,
                    color: themeGreen,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BtReceivePage(),
                        ),
                      ).then((txn) {
                        if (txn is TxnResult) {
                          setState(() {
                            balance += txn.amount;
                            lastCode = txn.code;
                            lastTime = txn.time;
                          });
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: "دریافت از QR",
                    enabled: true,
                    onTap: () async {
                      final r = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QrReceivePage()),
                      );
                      if (r is TxnResult) {
                        setState(() {
                          balance += r.amount;
                          lastCode = r.code;
                          lastTime = r.time;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("آخرین تراکنش دریافت‌شده",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text("کد: $lastCode",
                      style: const TextStyle(fontSize: 16)),
                  Text("زمان: $lastTime",
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFCCE2D2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _actionButton(
      {required String label,
      bool enabled = false,
      Color? color,
      required VoidCallback onTap}) {
    final bg = enabled ? (color ?? const Color(0xFF9DB5A3)) : const Color(0xFFBFC8C3);
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: const Color(0xFFBFC8C3),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

/// نتیجهٔ تراکنش ساده
class TxnResult {
  final int amount;
  final String code;
  final String time;
  TxnResult(this.amount, this.code, this.time);
}

/// دریافت با بلوتوث (نسخهٔ ساده با اسکن لیست دستگاه‌ها – فعلاً فقط اتصال/تأیید)
class BtReceivePage extends StatefulWidget {
  const BtReceivePage({super.key});
  @override
  State<BtReceivePage> createState() => _BtReceivePageState();
}

class _BtReceivePageState extends State<BtReceivePage> {
  final TextEditingController amountCtl = TextEditingController(text: "1000");
  bool paired = false;
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    devices.clear();
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    final results = await FlutterBluePlus.scanResults.first;
    setState(() {
      devices = results.map((e) => e.device).toList();
    });
    FlutterBluePlus.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("دریافت با بلوتوث", style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFE8F2EA),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: amountCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "مبلغ خرید", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _scan,
              child: const Text("اسکن دستگاه‌ها"),
            ),
            const SizedBox(height: 8),
            for (final d in devices)
              ListTile(
                title: Text(d.platformName.isEmpty ? d.remoteId.str : d.platformName),
                trailing: ElevatedButton(
                  onPressed: () async {
                    try {
                      await d.connect(timeout: const Duration(seconds: 5));
                      setState(() => paired = true);
                    } catch (_) {}
                  },
                  child: const Text("اتصال"),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(paired ? Icons.lock : Icons.lock_open,
                    color: paired ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Text(paired ? "اتصال امن" : "اتصال برقرار نیست"),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: paired
                  ? () {
                      final amt = int.tryParse(amountCtl.text) ?? 0;
                      final now = DateTime.now();
                      final code = "RCV-${now.millisecondsSinceEpoch % 1000000}";
                      Navigator.pop(context,
                          TxnResult(amt, code, now.toString().split('.').first));
                    }
                  : null,
              child: const Text("ثبت دریافت و بازگشت"),
            )
          ],
        ),
      ),
    );
  }
}

/// دریافت با QR (اسکن مبلغ از خریدار)
class QrReceivePage extends StatefulWidget {
  const QrReceivePage({super.key});
  @override
  State<QrReceivePage> createState() => _QrReceivePageState();
}

class _QrReceivePageState extends State<QrReceivePage> {
  final TextEditingController amountCtl = TextEditingController(text: "1000");
  bool shown = false;
  String? scanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("دریافت با QR", style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFE8F2EA),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: amountCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "مبلغ خرید", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => shown = true),
              child: const Text("برای نمایش به خریدار QR تولید"),
            ),
            const SizedBox(height: 12),
            if (shown)
              Center(
                child: QrImageView(
                  data: "AMT:${amountCtl.text}",
                  size: 220,
                ),
              ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration:
                  BoxDecoration(border: Border.all(color: Colors.black12)),
              child: MobileScanner(
                onDetect: (capture) {
                  final raw = capture.barcodes.first.rawValue ?? "";
                  setState(() => scanned = raw);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(scanned != null ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: scanned != null ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(scanned != null ? "اسکن دوطرفه تأیید شد" : "منتظر اسکن مقابل از خریدار"),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: scanned != null
                  ? () {
                      final amt = int.tryParse(amountCtl.text) ?? 0;
                      final now = DateTime.now();
                      final code = "RCV-${now.millisecondsSinceEpoch % 1000000}";
                      Navigator.pop(context,
                          TxnResult(amt, code, now.toString().split('.').first));
                    }
                  : null,
              child: const Text("ثبت دریافت و بازگشت"),
            )
          ],
        ),
      ),
    );
  }
}
