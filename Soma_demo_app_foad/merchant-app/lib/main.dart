import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SomaMerchantApp());
}

const _green = Color(0xFF2E7D32);
const _serviceId = 'soma.offline.demo';

class SomaMerchantApp extends StatelessWidget {
  const SomaMerchantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ فروشنده',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
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
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما — اپ فروشنده')),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('موجودی', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$balance', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('آخرین تراکنش دریافت‌شده', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('کد: $lastTxnId'),
              Text('زمان: ${lastTxnTime == null ? "—" : lastTxnTime!.toLocal()}'),
            ]),
          ),
        ],
      ),
    );
  }
}

/* ---------------- فروشنده: بلوتوث (Nearby) ---------------- */

class MerchantBluetoothPage extends StatefulWidget {
  const MerchantBluetoothPage({super.key});
  @override
  State<MerchantBluetoothPage> createState() => _MerchantBluetoothPageState();
}

class _MerchantBluetoothPageState extends State<MerchantBluetoothPage> {
  String status = 'برای شروع تبلیغ (Advertise) دکمه زیر را بزنید';
  String? endpointId;

  @override
  void dispose() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => status = 'درحال Advertise… منتظر اتصال خریدار');
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();

    Nearby().startAdvertising(
      'merchant',
      Strategy.P2P_POINT_TO_POINT,
      onConnectionInitiated: (id, info) {
        endpointId = id;
        Nearby().acceptConnection(
          id,
          onPayLoadRecieved: _onPayload,
          onPayloadTransferUpdate: (id, update) {},
        );
      },
      onConnectionResult: (id, statusz) {
        setState(() => status = 'اتصال برقرار شد');
      },
      onDisconnected: (id) {
        setState(() => status = 'قطع شد');
      },
      serviceId: _serviceId,
    );
  }

  void _onPayload(String id, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final data = utf8.decode(payload.bytes!);
      try {
        final map = jsonDecode(data) as Map<String, dynamic>;
        if (map['t'] == 'PAY') {
          final amount = (map['amount'] as num).toInt();
          // ارسال Ack ساده
          Nearby().sendBytesPayload(id, Uint8List.fromList(utf8.encode('ACK:$amount')));
          if (mounted) Navigator.of(context).pop(amount);
        }
      } catch (_) {
        setState(() => status = 'Payload نامعتبر: $data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با بلوتوث')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _start,
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('شروع Advertise', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(status),
        ],
      ),
    );
  }
}

/* ---------------- فروشنده: QR واقعی ---------------- */

class MerchantQRPage extends StatefulWidget {
  const MerchantQRPage({super.key});
  @override
  State<MerchantQRPage> createState() => _MerchantQRPageState();
}

class _MerchantQRPageState extends State<MerchantQRPage> {
  final TextEditingController amount = TextEditingController();
  bool shown = false;
  String? buyerAck;

  @override
  void dispose() { amount.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final amt = int.tryParse(amount.text) ?? 0;
    final payload = jsonEncode({'t':'INVOICE','amount':amt,'ts':DateTime.now().toIso8601String()});

    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: amt>0 ? (){ setState(()=>shown=true); } : null,
            child: const Text('تولید QR برای نمایش به خریدار'),
          ),
          const SizedBox(height: 8),
          if (shown)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: QrImageView(data: payload, size: 220),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: shown ? () async {
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_)=>const _ScanPage()),
              );
              if (result != null) setState(()=>buyerAck=result);
            } : null,
            child: const Text('تأیید اسکن متقابل از خریدار'),
          ),
          const SizedBox(height: 8),
          Text(buyerAck==null ? 'در انتظار Ack خریدار' : 'Ack خریدار: $buyerAck'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: buyerAck!=null && amt>0 ? ()=>Navigator.of(context).pop(amt) : null,
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: const Text('ثبت دریافت و بازگشت', style: TextStyle(color: Colors.white)),
          ),
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
