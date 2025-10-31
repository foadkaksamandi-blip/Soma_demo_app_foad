import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ فروشنده',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF3F7F4),
        fontFamily: 'Roboto',
      ),
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
  int balance = 0;

  String lastRxCode = '—';
  String lastRxTime = '—';

  // مبلغ برای دریافت (QR/BT)
  final TextEditingController _amountCtl = TextEditingController(text: '');

  // ---- Bluetooth (اسکن واقعی BLE، دریافت مبلغ شبیه‌سازی) ----
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  bool _bleScanning = false;
  List<ScanResult> _results = [];

  Future<void> _scanBle() async {
    setState(() {
      _results = [];
      _bleScanning = true;
    });
    await _ble.startScan(timeout: const Duration(seconds: 6));
    _ble.scanResults.listen((list) {
      setState(() => _results = list);
    });
    await Future.delayed(const Duration(seconds: 6));
    await _ble.stopScan();
    setState(() => _bleScanning = false);
  }

  Future<void> _simulateBleReceive(ScanResult r, int amount) async {
    if (amount <= 0) return;
    setState(() {
      balance += amount;
      lastRxCode = 'RCV-${Random().nextInt(900000) + 100000}';
      lastRxTime = DateTime.now().toString();
    });
    _snack('دریافت بلوتوث (نمایشی) از ${r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.str}');
  }

  // ---- QR: تولید و نمایش ----
  String? _qrPayload; // SOMA|AMT|TS|RAND
  void _makeQr() {
    final amt = int.tryParse(_amountCtl.text.trim()) ?? 0;
    if (amt <= 0) {
      _snack('مبلغ نامعتبر است');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(900000) + 100000;
    setState(() {
      _qrPayload = 'SOMA|$amt|$now|$rand';
    });
  }

  void _confirmQrReceived() {
    final amt = int.tryParse(_amountCtl.text.trim()) ?? 0;
    if (amt <= 0 || _qrPayload == null) {
      _snack('ابتدا مبلغ را وارد و QR را تولید کنید');
      return;
    }
    setState(() {
      balance += amt;
      lastRxCode = 'RCV-${Random().nextInt(900000) + 100000}';
      lastRxTime = DateTime.now().toString();
      _qrPayload = null;
      _amountCtl.text = '';
    });
    _snack('دریافت با QR ثبت شد');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ آفلاین سوما — اپ فروشنده')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // موجودی
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('موجودی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    balance.toString(),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // دکمه‌ها
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => _ReceiveQrPage(
                        amountCtl: _amountCtl,
                        qrPayload: _qrPayload,
                        onMakeQr: _makeQr,
                        onConfirm: _confirmQrReceived,
                      )),
                    ),
                    child: const Text('دریافت از QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _bleScanning ? null : _scanBle,
                    child: Text(_bleScanning ? 'در حال جستجو…' : 'دریافت از بلوتوث'),
                  ),
                ),
              ],
            ),

            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('دستگاه‌های BLE نزدیک', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const Divider(height: 1),
                    for (final r in _results.take(8))
                      ListTile(
                        title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : 'دستگاه ناشناس'),
                        subtitle: Text(r.device.remoteId.str),
                        trailing: Text('RSSI ${r.rssi}'),
                        onTap: () async {
                          final amt = int.tryParse(_amountCtl.text.trim()) ?? 0;
                          if (amt <= 0) {
                            _snack('مبلغ دریافت را در بالا وارد کنید');
                            return;
                          }
                          await _simulateBleReceive(r, amt);
                        },
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // آخرین دریافتی
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('آخرین تراکنش دریافت‌شده', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('کد: $lastRxCode'),
                  Text('زمان: $lastRxTime'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// صفحهٔ دریافت با QR (تولید QR و ثبت دوطرفه)
class _ReceiveQrPage extends StatelessWidget {
  final TextEditingController amountCtl;
  final String? qrPayload;
  final VoidCallback onMakeQr;
  final VoidCallback onConfirm;

  const _ReceiveQrPage({
    required this.amountCtl,
    required this.qrPayload,
    required this.onMakeQr,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دریافت با QR')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: amountCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ خرید',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            FilledButton.tonal(
              onPressed: onMakeQr,
              child: const Text('برای نمایش به خریدار QR تولید'),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Center(
                child: qrPayload == null
                    ? const Text('روی دکمهٔ بالا بزنید تا QR ساخته شود')
                    : QrImageView(
                        data: qrPayload!,
                        version: QrVersions.auto,
                        size: 220,
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // چک‌باکس‌های نمایشیِ تأیید اسکن دوطرفه را حذف کردیم و ثبت نهایی را یک‌دکمه‌ای کردیم
            FilledButton(
              onPressed: onConfirm,
              child: const Text('ثبت دریافت و بازگشت'),
            ),
          ],
        ),
      ),
    );
  }
}
