import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SomaBuyerApp());
}

const _green = Color(0xFF2E7D32);

class SomaBuyerApp extends StatelessWidget {
  const SomaBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ خریدار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF3F7F5),
        useMaterial3: true,
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
  // موجودی‌ها
  int balanceMain = 100000;
  int balanceSubsidy = 50000;
  int balanceEmergency = 20000;
  int balanceCrypto = 300000;
  // نمایش
  String lastTxnId = '—';
  String lastTxnMethod = '—';
  DateTime? lastTxnTime;

  void _applyTxn(int amount, String source, String method, {bool addToSeller = true}) {
    setState(() {
      switch (source) {
        case 'اصلی':
          balanceMain -= amount;
          break;
        case 'یارانه‌ای':
          balanceSubsidy -= amount;
          break;
        case 'اضطراری ملی':
          balanceEmergency -= amount;
          break;
        case 'رمز‌ارز ملی':
          balanceCrypto -= amount;
          break;
      }
      lastTxnId = 'TXN-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      lastTxnMethod = '$method / $source / $amount';
      lastTxnTime = DateTime.now();
    });
  }

  Widget _balanceCard(String title, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green.withOpacity(.25)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _goBluetooth() async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const BuyerBluetoothPage()),
    );
    if (res != null) {
      _applyTxn(res['amount'] as int, res['source'] as String, 'بلوتوث');
    }
  }

  Future<void> _goQR() async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const BuyerQRPage()),
    );
    if (res != null) {
      _applyTxn(res['amount'] as int, res['source'] as String, 'QR');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'اپ آفلاین سوما — اپ خریدار';
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _balanceCard('موجودی اصلی', balanceMain),
              _balanceCard('موجودی یارانه‌ای', balanceSubsidy),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _balanceCard('موجودی اضطراری ملی', balanceEmergency),
              _balanceCard('موجودی رمز‌ارز ملی', balanceCrypto),
            ],
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
                  child: const Text('پرداخت با بلوتوث', style: TextStyle(color: Colors.white, fontSize: 16)),
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
                  child: const Text('پرداخت با QR', style: TextStyle(color: Colors.black87, fontSize: 16)),
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
                const Text('آخرین تراکنش', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('کد: $lastTxnId'),
                Text('جزئیات: $lastTxnMethod'),
                Text('زمان: ${lastTxnTime == null ? "—" : lastTxnTime!.toLocal()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————— صفحات پرداخت خریدار —————————————

class BuyerBluetoothPage extends StatefulWidget {
  const BuyerBluetoothPage({super.key});
  @override
  State<BuyerBluetoothPage> createState() => _BuyerBluetoothPageState();
}

class _BuyerBluetoothPageState extends State<BuyerBluetoothPage> {
  bool secure = false;
  String source = 'اصلی';
  final TextEditingController amount = TextEditingController();

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت بلوتوث (آفلاین)')),
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
            child: const Text('شروع و جستجوی فروشنده', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(secure ? Icons.lock : Icons.lock_open, color: secure ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(secure ? 'اتصال ایمن برقرار شد' : 'اتصال برقرار نیست'),
            ],
          ),
          const SizedBox(height: 16),
          _SourceChips(
            value: source,
            onChanged: (v) => setState(() => source = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ خرید',
              border: OutlineInputBorder(),
              hintText: 'مثال: 25000',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: secure && (int.tryParse(amount.text) ?? 0) > 0
                ? () {
                    Navigator.of(context).pop({
                      'amount': int.parse(amount.text),
                      'source': source,
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('پرداخت', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class BuyerQRPage extends StatefulWidget {
  const BuyerQRPage({super.key});
  @override
  State<BuyerQRPage> createState() => _BuyerQRPageState();
}

class _BuyerQRPageState extends State<BuyerQRPage> {
  String source = 'اصلی';
  final TextEditingController amount = TextEditingController();
  bool scanned = false;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت QR (آفلاین)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SourceChips(
            value: source,
            onChanged: (v) => setState(() => source = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ خرید',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    // شبیه‌سازی تولید/نمایش QR
                    await Future.delayed(const Duration(milliseconds: 600));
                    setState(() => scanned = true);
                  },
                  child: const Text('تولید و اسکن QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(scanned ? Icons.check_circle : Icons.qr_code_2, color: scanned ? Colors.green : Colors.black54),
              const SizedBox(width: 8),
              Text(scanned ? 'QR معتبر اسکن شد' : 'در انتظار اسکن'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: scanned && (int.tryParse(amount.text) ?? 0) > 0
                ? () {
                    Navigator.of(context).pop({
                      'amount': int.parse(amount.text),
                      'source': source,
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('تأیید و بازگشت', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SourceChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SourceChips({required this.value, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['اصلی', 'یارانه‌ای', 'اضطراری ملی', 'رمز‌ارز ملی'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        final selected = e == value;
        return ChoiceChip(
          label: Text(e),
          selected: selected,
          onSelected: (_) => onChanged(e),
          selectedColor: _green.withOpacity(.2),
        );
      }).toList(),
    );
  }
}
