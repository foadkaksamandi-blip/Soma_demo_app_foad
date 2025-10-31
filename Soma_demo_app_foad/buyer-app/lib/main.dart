import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ خریدار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFF3F7F4),
        fontFamily: 'Roboto',
      ),
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
  // موجودی‌ها (دمویی – داخل دستگاه و آفلاین)
  int balanceMain = 0;
  int balanceSubsidy = 50000;
  int balanceEmergency = 20000;
  int balanceNatCrypto = 300000;

  String lastTxCode = '—';
  String lastTxInfo = '—';
  String lastTxTime = '—';

  // ---- Bluetooth (واقعی: اسکن BLE؛ انتقال مبلغ شبیه‌سازی) ----
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

  Future<void> _simulateBlePayment(ScanResult r, int amount) async {
    // اینجا فعلاً تبادل دیتا BLE را شبیه‌سازی می‌کنیم تا جریان کامل شود.
    // پس از بیلد سبز، مرحله انتقال واقعی را اضافه می‌کنیم.
    if (amount <= 0) return;
    if (balanceMain < amount) {
      _snack('موجودی اصلی کافی نیست');
      return;
    }
    setState(() {
      balanceMain -= amount;
      final code = 'TXN-${Random().nextInt(900000) + 100000}';
      lastTxCode = code;
      lastTxInfo = '$amount / بلوتوث / اصلی → ${r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.str}';
      lastTxTime = DateTime.now().toString();
    });
    _snack('پرداخت بلوتوث (نمایشی) ثبت شد');
  }

  // ---- QR (واقعی: اسکن با دوربین) ----
  Future<void> _payWithQr() async {
    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (payload == null) return;

    // قالب ساده: SOMA|AMT|TS|RAND
    try {
      final parts = payload.split('|');
      if (parts.length < 4 || parts[0] != 'SOMA') {
        _snack('فرمت QR نامعتبر است');
        return;
      }
      final amount = int.tryParse(parts[1]) ?? 0;
      if (amount <= 0) {
        _snack('مبلغ نامعتبر');
        return;
      }
      if (balanceMain < amount) {
        _snack('موجودی اصلی کافی نیست');
        return;
      }
      setState(() {
        balanceMain -= amount;
        lastTxCode = 'TXN-${Random().nextInt(900000) + 100000}';
        lastTxInfo = '$amount / QR / اصلی';
        lastTxTime = DateTime.now().toString();
      });
      _snack('پرداخت QR انجام شد');
    } catch (_) {
      _snack('پردازش QR ناموفق بود');
    }
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
        appBar: AppBar(
          title: const Text('اپ آفلاین سوما — اپ خریدار'),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _balanceTile('موجودی اصلی', balanceMain),
                _balanceTile('موجودی یارانه‌ای', balanceSubsidy),
                _balanceTile('موجودی اضطراری ملی', balanceEmergency),
                _balanceTile('موجودی رمزارز ملی', balanceNatCrypto),
              ],
            ),

            const SizedBox(height: 16),

            // دکمه‌های پرداخت
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _payWithQr(),
                    child: const Text('پرداخت با QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _bleScanning ? null : _scanBle,
                    child: Text(_bleScanning ? 'در حال جستجو…' : 'پرداخت با بلوتوث'),
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
                          // مبلغ نمونه برای پرداخت نمایشی بلوتوث
                          await _simulateBlePayment(r, 100000);
                        },
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // آخرین تراکنش
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
                  const Text('آخرین تراکنش', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('کد: $lastTxCode'),
                  Text('جزئیات: $lastTxInfo'),
                  Text('زمان: $lastTxTime'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceTile(String title, int value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _QrScanPage extends StatelessWidget {
  const _QrScanPage();

  @override
  Widget build(BuildContext context) {
    final controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اسکن QR')),
        body: Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final codes = capture.barcodes;
                if (codes.isNotEmpty && codes.first.rawValue != null) {
                  Navigator.of(context).pop<String>(codes.first.rawValue!);
                }
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'دوربین را به سوی QR فروشنده بگیرید',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        backgroundColor: Colors.black54,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
