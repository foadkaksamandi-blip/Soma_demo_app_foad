import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SomaBuyerApp());
}

const _green = Color(0xFF2E7D32);
const _serviceId = 'soma.offline.demo';

class SomaBuyerApp extends StatelessWidget {
  const SomaBuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ خریدار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
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
  int balanceMain = 100000;
  int balanceSubsidy = 50000;
  int balanceEmergency = 20000;
  int balanceCrypto = 300000;

  String lastTxnId = '—';
  String lastTxnMethod = '—';
  DateTime? lastTxnTime;

  void _applyTxn(int amount, String source, String method) {
    setState(() {
      switch (source) {
        case 'اصلی': balanceMain -= amount; break;
        case 'یارانه‌ای': balanceSubsidy -= amount; break;
        case 'اضطراری ملی': balanceEmergency -= amount; break;
        case 'رمز‌ارز ملی': balanceCrypto -= amount; break;
      }
      lastTxnId = 'TXN-${DateTime.now().millisecondsSinceEpoch % 1000000}';
      lastTxnMethod = '$method / $source / $amount';
      lastTxnTime = DateTime.now();
    });
  }

  Widget _balanceCard(String title, int value) => Expanded(
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

  Future<void> _goBluetooth() async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const BuyerBluetoothPage()),
    );
    if (res != null) _applyTxn(res['amount'], res['source'], 'بلوتوث');
  }

  Future<void> _goQR() async {
    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const BuyerQRPage()),
    );
    if (res != null) _applyTxn(res['amount'], res['source'], 'QR');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما — اپ خریدار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            _balanceCard('موجودی اصلی', balanceMain),
            _balanceCard('موجودی یارانه‌ای', balanceSubsidy),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _balanceCard('موجودی اضطراری ملی', balanceEmergency),
            _balanceCard('موجودی رمز‌ارز ملی', balanceCrypto),
          ]),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('آخرین تراکنش', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('کد: $lastTxnId'),
              Text('جزئیات: $lastTxnMethod'),
              Text('زمان: ${lastTxnTime == null ? "—" : lastTxnTime!.toLocal()}'),
            ]),
          ),
        ],
      ),
    );
  }
}

/* ---------------- خریدار: بلوتوث (Nearby) ---------------- */

class BuyerBluetoothPage extends StatefulWidget {
  const BuyerBluetoothPage({super.key});
  @override
  State<BuyerBluetoothPage> createState() => _BuyerBluetoothPageState();
}

class _BuyerBluetoothPageState extends State<BuyerBluetoothPage> {
  final TextEditingController amount = TextEditingController();
  String source = 'اصلی';
  String status = 'برای جستجو دکمه "شروع" را بزنید';
  String? endpointId;

  @override
  void dispose() {
    Nearby().stopAllEndpoints();
    Nearby().stopDiscovery();
    amount.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => status = 'درحال جستجوی فروشنده…');
    await Nearby().stopAllEndpoints();
    await Nearby().stopDiscovery();

    Nearby().startDiscovery(
      'buyer',
      Strategy.P2P_POINT_TO_POINT,
      onEndpointFound: (id, name, serviceId) async {
        setState(() { status = 'پیدا شد: $name — اتصال…'; });
        endpointId = id;
        await Nearby().requestConnection(
          'buyer',
          id,
          onConnectionInitiated: (id, info) => Nearby().acceptConnection(
            id,
            onPayLoadRecieved: _onPayload,
            onPayloadTransferUpdate: (id, update) {},
          ),
          onConnectionResult: (id, statusz) { setState(() => status = 'Connected'); },
          onDisconnected: (id) { setState(() => status = 'قطع شد'); },
        );
      },
      onEndpointLost: (id) {},
      serviceId: _serviceId,
    );
  }

  void _onPayload(String id, Payload payload) async {
    // فروشنده ممکن است ACK برگرداند
    if (payload.type == PayloadType.BYTES) {
      final msg = utf8.decode(payload.bytes!);
      setState(() => status = 'پیام از فروشنده: $msg');
    }
  }

  Future<void> _send() async {
    final amt = int.tryParse(amount.text) ?? 0;
    if (endpointId == null || amt <= 0) return;
    final data = jsonEncode({
      't': 'PAY',
      'amount': amt,
      'source': source,
      'ts': DateTime.now().toIso8601String(),
    });
    await Nearby().sendBytesPayload(endpointId!, Uint8List.fromList(utf8.encode(data)));
    if (!mounted) return;
    Navigator.of(context).pop({'amount': amt, 'source': source});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت بلوتوث (واقعی)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _start,
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('شروع و جستجو', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Text(status),
          const SizedBox(height: 16),
          _SourceChips(value: source, onChanged: (v) => setState(() => source = v)),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _send,
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('ارسال مبلغ به فروشنده', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/* ---------------- خریدار: QR واقعی ---------------- */

class BuyerQRPage extends StatefulWidget {
  const BuyerQRPage({super.key});
  @override
  State<BuyerQRPage> createState() => _BuyerQRPageState();
}

class _BuyerQRPageState extends State<BuyerQRPage> {
  String source = 'اصلی';
  final TextEditingController amount = TextEditingController();
  String? merchantPayload; // داده دریافتی از فروشنده
  bool ackShown = false;

  @override
  void dispose() { amount.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final amt = int.tryParse(amount.text) ?? 0;
    final ack = jsonEncode({
      't': 'ACK',
      'amount': amt,
      'source': source,
      'ts': DateTime.now().toIso8601String(),
    });

    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت QR (واقعی)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SourceChips(value: source, onChanged: (v) => setState(() => source = v)),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              // اسکن QR فروشنده (مبلغ و شناسه)
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const _ScanPage()),
              );
              if (result != null) setState(() => merchantPayload = result);
            },
            child: const Text('اسکن QR فروشنده'),
          ),
          const SizedBox(height: 8),
          Text(merchantPayload == null ? 'هنوز چیزی اسکن نشده' : 'داده فروشنده: $merchantPayload'),
          const SizedBox(height: 12),
          if (merchantPayload != null && amt > 0)
            Column(children: [
              const Text('QR تأیید خریدار را به فروشنده نشان دهید:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: ack, size: 220),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() => ackShown = true);
                  Navigator.of(context).pop({'amount': amt, 'source': source});
                },
                style: ElevatedButton.styleFrom(backgroundColor: _green),
                child: const Text('تأیید و بازگشت', style: TextStyle(color: Colors.white)),
              ),
            ]),
        ],
      ),
    );
  }
}

class _ScanPage extends StatelessWidget {
  const _ScanPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) Navigator.of(context).pop(code);
        },
      ),
    );
  }
}

class _SourceChips extends StatelessWidget {
  final String value; final ValueChanged<String> onChanged;
  const _SourceChips({required this.value, required this.onChanged, super.key});
  @override
  Widget build(BuildContext context) {
    final items = ['اصلی','یارانه‌ای','اضطراری ملی','رمز‌ارز ملی'];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: items.map((e){
        final selected = e==value;
        return ChoiceChip(
          label: Text(e), selected: selected,
          onSelected: (_)=>onChanged(e),
          selectedColor: _green.withOpacity(.2),
        );
      }).toList(),
    );
  }
}
