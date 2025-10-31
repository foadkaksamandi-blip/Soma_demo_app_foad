import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SomaMerchantApp());
}

const _green = Color(0xFF2E7D32);

class SomaMerchantApp extends StatelessWidget {
  const SomaMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ فروشنده',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF3F7F5),
        useMaterial3: true,
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
  String lastTxnId = '—';
  DateTime? lastTxnTime;

  void _receive(int amount) {
    setState(() {
      balance += amount;
      lastTxnId = 'RCV-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      lastTxnTime = DateTime.now();
    });
  }

  Future<void> _goBluetooth() async {
    final res = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const MerchantBluetoothPage()),
    );
    if (res != null) _receive(res);
  }

  Future<void> _goQR() async {
    final res = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const MerchantQRPage()),
    );
    if (res != null) _receive(res);
  }

  @override
  Widget build(BuildContext context) {
    final title = 'اپ آفلاین سوما — اپ فروشنده';
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withOpacity(.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('موجودی', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('$balance', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _goBluetooth,
                  child: const Text('دریافت از بلوتوث', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green.withOpacity(.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _goQR,
                  child: const Text('دریافت از QR', style: TextStyle(color: Colors.black87, fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withOpacity(.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('آخرین تراکنش دریافت‌شده', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('کد: $lastTxnId'),
                Text('زمان: ${lastTxnTime == null ? "—" : lastTxnTime!.toLocal()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————— صفحات دریافت فروشنده —————————————

class MerchantBluetoothPage extends StatefulWidget {
  const MerchantBluetoothPage({super.key});
  @override
  State<MerchantBluetoothPage> createState() => _MerchantBluetoothPageState();
}

class _MerchantBluetoothPageState extends State<MerchantBluetoothPage> {
  bool secure = false;
  final TextEditingController amount = TextEditingController();

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با بلوتوث')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 800));
              setState(() => secure = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('شروع و جفت‌سازی امن', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(secure ? Icons.lock : Icons.lock_open, color: secure ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(secure ? 'اتصال ایمن برقرار شد' : 'در انتظار اتصال'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ دریافتی از خریدار',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: secure && (int.tryParse(amount.text) ?? 0) > 0
                ? () => Navigator.of(context).pop(int.parse(amount.text))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('تأیید دریافت', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class MerchantQRPage extends StatefulWidget {
  const MerchantQRPage({super.key});
  @override
  State<MerchantQRPage> createState() => _MerchantQRPageState();
}

class _MerchantQRPageState extends State<MerchantQRPage> {
  final TextEditingController amount = TextEditingController();
  bool shown = false;
  bool scannedBack = false;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ خرید',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              if ((int.tryParse(amount.text) ?? 0) <= 0) return;
              await Future.delayed(const Duration(milliseconds: 600));
              setState(() => shown = true);
            },
            child: const Text('تولید QR برای نمایش به خریدار'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(shown ? Icons.qr_code_2 : Icons.qr_code, color: Colors.black87),
              const SizedBox(width: 8),
              Text(shown ? 'QR روی صفحه نمایش داده شد' : 'هنوز تولید نشده'),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: shown
                ? () async {
                    await Future.delayed(const Duration(milliseconds: 600));
                    setState(() => scannedBack = true);
                  }
                : null,
            child: const Text('تأیید اسکن متقابل از خریدار'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(scannedBack ? Icons.check_circle : Icons.hourglass_empty,
                  color: scannedBack ? Colors.green : Colors.black54),
              const SizedBox(width: 8),
              Text(scannedBack ? 'اسکن دوطرفه تأیید شد' : 'در انتظار تأیید خریدار'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: scannedBack && (int.tryParse(amount.text) ?? 0) > 0
                ? () => Navigator.of(context).pop(int.parse(amount.text))
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('ثبت دریافت و بازگشت', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
