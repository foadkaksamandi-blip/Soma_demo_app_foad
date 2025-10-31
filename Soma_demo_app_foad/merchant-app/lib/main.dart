import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';

void main() => runApp(const MerchantApp());

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ فروشنده',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF3F8F5),
        useMaterial3: true,
      ),
      home: const MerchantHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});
  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  int balance = 200000;
  String lastTxnId = '-';
  String lastTxnDetail = '-';
  String lastTxnTime = '-';

  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  String myName = 'merchant_app';
  Map<String, ConnectionInfo> endpoints = {};

  int? amount;
  String src = 'main';
  bool connected = false;

  Future<void> _startBTReceiveFlow() async {
    bool locationGranted = await Nearby().checkLocationPermission();
    if (!locationGranted) {
      locationGranted = await Nearby().askLocationPermission();
      if (!locationGranted) return;
    }

    final bool locEnabled = await Nearby().checkLocationEnabled();
    if (!locEnabled) await Nearby().enableLocationServices();

    await Nearby().startAdvertising(
      myName,
      strategy,
      onConnectionInitiated: (id, info) async {
        endpoints[id] = info;
        await Nearby().acceptConnection(
          id,
          onPayLoadReceived: (eid, payload) async {
            if (payload.type == PayloadType.BYTES) {
              final data = jsonDecode(utf8.decode(payload.bytes!));
              if (data['type'] == 'ack' && data['ok'] == true) {
                _addBalance(data['amount']);
                _setLast(data['txnId'],
                    'بلوتوث / ${data['src']} / ${data['amount']}');
              }
            }
          },
          onPayloadTransferUpdate: (id, update) {},
        );

        await _sendPaymentRequest(id);
      },
      onConnectionResult: (id, status) {
        setState(() => connected = status == Status.CONNECTED);
      },
      onDisconnected: (id) {
        endpoints.remove(id);
        setState(() => connected = false);
      },
    );
  }

  Future<void> _sendPaymentRequest(String id) async {
    if (amount == null) return;
    final req = {
      'type': 'req',
      'amount': amount,
      'src': src,
    };
    Nearby().sendBytesPayload(
        id, Uint8List.fromList(utf8.encode(jsonEncode(req))));
  }

  void _addBalance(int a) {
    setState(() => balance += a);
  }

  void _setLast(String id, String detail) {
    setState(() {
      lastTxnId = id;
      lastTxnDetail = detail;
      lastTxnTime = DateTime.now().toString().split('.').first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اپ آفلاین سوما — فروشنده')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _balanceCard(),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید'),
            onChanged: (v) => amount = int.tryParse(v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: src,
            items: const [
              DropdownMenuItem(value: 'main', child: Text('موجودی اصلی')),
              DropdownMenuItem(value: 'subsidy', child: Text('یارانه‌ای')),
              DropdownMenuItem(value: 'emergency', child: Text('اضطراری ملی')),
              DropdownMenuItem(value: 'ncrypto', child: Text('رمزارز ملی')),
            ],
            onChanged: (v) => setState(() => src = v!),
            decoration: const InputDecoration(labelText: 'منبع پرداخت'),
          ),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: _startBTReceiveFlow,
              child: const Text('دریافت با بلوتوث')),
          const SizedBox(height: 12),
          FilledButton.tonal(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            MerchantQrFlow(onFinish: (amount, src) {
                              _addBalance(amount);
                              _setLast(_genTxnId('QR'),
                                  'QR / $src / $amount');
                            })));
              },
              child: const Text('دریافت با QR')),

          const SizedBox(height: 16),
          _lastTxn(),
        ]),
      ),
    );
  }

  String _genTxnId(String prefix) {
    final n = DateTime.now().millisecondsSinceEpoch % 999999;
    return '${prefix}-${n.toString().padLeft(6, '0')}';
  }

  Widget _balanceCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('موجودی فعلی',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('$balance',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _lastTxn() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('آخرین تراکنش',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('کد: $lastTxnId'),
        Text('جزئیات: $lastTxnDetail'),
        Text('زمان: $lastTxnTime'),
      ]),
    );
  }
}

class MerchantQrFlow extends StatefulWidget {
  final void Function(int amount, String src) onFinish;
  const MerchantQrFlow({super.key, required this.onFinish});
  @override
  State<MerchantQrFlow> createState() => _MerchantQrFlowState();
}

class _MerchantQrFlowState extends State<MerchantQrFlow> {
  int? amount;
  String src = 'main';
  bool qrShown = false;
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با QR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید'),
            onChanged: (v) => amount = int.tryParse(v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: src,
            items: const [
              DropdownMenuItem(value: 'main', child: Text('موجودی اصلی')),
              DropdownMenuItem(value: 'subsidy', child: Text('یارانه‌ای')),
              DropdownMenuItem(value: 'emergency', child: Text('اضطراری ملی')),
              DropdownMenuItem(value: 'ncrypto', child: Text('رمزارز ملی')),
            ],
            onChanged: (v) => setState(() => src = v!),
            decoration: const InputDecoration(labelText: 'منبع پرداخت'),
          ),
          const SizedBox(height: 12),
          if (!qrShown)
            FilledButton(
                onPressed: () => setState(() => qrShown = true),
                child: const Text('تولید QR برای خریدار'))
          else if (!confirmed)
            Expanded(
              child: Column(children: [
                const Text('این QR را خریدار باید اسکن کند'),
                const SizedBox(height: 8),
                QrImageView(
                  data: jsonEncode(
                      {'type': 'ask', 'amount': amount, 'src': src}),
                  size: 220,
                ),
                const SizedBox(height: 16),
                const Text('منتظر تأیید خریدار...'),
                Expanded(
                  child: MobileScanner(onDetect: (capture) {
                    final code = capture.barcodes.first.rawValue;
                    if (code != null) {
                      final data = jsonDecode(code);
                      if (data['type'] == 'confirm') {
                        setState(() => confirmed = true);
                        widget.onFinish(data['amount'], data['src']);
                      }
                    }
                  }),
                )
              ]),
            )
          else
            Expanded(
                child: Center(
                    child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 72),
                const Text('تراکنش موفق بود'),
                FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('بازگشت به صفحه اصلی')),
              ],
            ))),
        ]),
      ),
    );
  }
}
