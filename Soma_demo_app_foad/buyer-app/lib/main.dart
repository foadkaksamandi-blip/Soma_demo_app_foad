import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — اپ خریدار',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF3F8F5),
        useMaterial3: true,
      ),
      home: const BuyerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

enum BalanceSource { main, subsidy, emergency, nationalCrypto }

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});
  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  int mainBalance = 100000;
  int subsidyBalance = 50000;
  int emergencyBalance = 20000;
  int nationalCryptoBalance = 300000;

  String lastTxnId = '-';
  String lastTxnDetail = '-';
  String lastTxnTime = '-';

  final Strategy strategy = Strategy.P2P_POINT_TO_POINT;
  String myName = 'buyer_app';
  Map<String, ConnectionInfo> endpoints = {};
  bool isDiscovering = false;

  Future<void> _startBTPaymentFlow() async {
    bool locationGranted = await Nearby().checkLocationPermission();
    if (!locationGranted) {
      locationGranted = await Nearby().askLocationPermission();
      if (!locationGranted) return;
    }

    final bool locEnabled = await Nearby().checkLocationEnabled();
    if (!locEnabled) await Nearby().enableLocationServices();

    setState(() => isDiscovering = true);

    await Nearby().startDiscovery(
      myName,
      strategy,
      onEndpointFound: (id, name, serviceId) async {
        if (name.contains('merchant_app') || name.contains('merchant')) {
          await Nearby().requestConnection(
            myName,
            id,
            onConnectionInitiated: (id, info) async {
              endpoints[id] = info;
              await Nearby().acceptConnection(
                id,
                onPayLoadReceived: (eid, payload) async {
                  if (payload.type == PayloadType.BYTES) {
                    final data = jsonDecode(utf8.decode(payload.bytes!));
                    if (data['type'] == 'req') {
                      final ok = await _confirmDialog(
                          'درخواست پرداخت',
                          'فروشنده مبلغ ${data['amount']} از منبع ${data['src']} درخواست کرد. آیا تأیید می‌کنی؟');
                      if (ok) {
                        final success =
                            _deductFromSource(data['amount'], data['src']);
                        final txnId = _genTxnId('BT');
                        final ack = {
                          'type': 'ack',
                          'ok': success,
                          'txnId': txnId,
                          'time': DateTime.now().toIso8601String(),
                          'src': data['src'],
                          'amount': data['amount']
                        };
                        Nearby().sendBytesPayload(
                            id,
                            Uint8List.fromList(
                                utf8.encode(jsonEncode(ack))));
                        if (success) {
                          _setLast(txnId,
                              'بلوتوث / ${data['src']} / ${data['amount']}');
                        }
                      } else {
                        Nearby().sendBytesPayload(
                            id,
                            Uint8List.fromList(utf8.encode(
                                jsonEncode({'type': 'ack', 'ok': false}))));
                      }
                    }
                  }
                },
                onPayloadTransferUpdate: (a, b) {},
              );
            },
            onConnectionResult: (id, status) {},
            onDisconnected: (id) => endpoints.remove(id),
          );
        }
      },
      onEndpointLost: (id) {},
    );
  }

  bool _deductFromSource(int amount, String src) {
    bool success = false;
    setState(() {
      switch (src) {
        case 'main':
          if (mainBalance >= amount) {
            mainBalance -= amount;
            success = true;
          }
          break;
        case 'subsidy':
          if (subsidyBalance >= amount) {
            subsidyBalance -= amount;
            success = true;
          }
          break;
        case 'emergency':
          if (emergencyBalance >= amount) {
            emergencyBalance -= amount;
            success = true;
          }
          break;
        case 'ncrypto':
          if (nationalCryptoBalance >= amount) {
            nationalCryptoBalance -= amount;
            success = true;
          }
          break;
      }
    });
    return success;
  }

  String _genTxnId(String prefix) {
    final n = DateTime.now().millisecondsSinceEpoch % 999999;
    return '${prefix}-${n.toString().padLeft(6, '0')}';
  }

  void _setLast(String id, String detail) {
    setState(() {
      lastTxnId = id;
      lastTxnDetail = detail;
      lastTxnTime = DateTime.now().toString().split('.').first;
    });
  }

  Future<bool> _confirmDialog(String title, String msg) async {
    bool ok = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو')),
          FilledButton(
              onPressed: () {
                ok = true;
                Navigator.pop(context);
              },
              child: const Text('تأیید')),
        ],
      ),
    );
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final title = 'اپ آفلاین سوما — خریدار';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _balanceCard('موجودی اصلی', mainBalance),
          Row(children: [
            Expanded(child: _balanceCard('یارانه‌ای', subsidyBalance)),
            const SizedBox(width: 12),
            Expanded(child: _balanceCard('اضطراری ملی', emergencyBalance)),
          ]),
          _balanceCard('رمزارز ملی', nationalCryptoBalance),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: _startBTPaymentFlow,
                child: const Text('پرداخت با بلوتوث'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => BuyerQrFlow(onFinish: (amount, src) {
                                _deductFromSource(amount, src);
                                _setLast(_genTxnId('TXN'),
                                    'QR / $src / $amount');
                              })));
                },
                child: const Text('پرداخت با QR'),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _lastTxn(),
        ]),
      ),
    );
  }

  Widget _balanceCard(String title, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 6),
        Text('$value',
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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

class BuyerQrFlow extends StatefulWidget {
  final void Function(int amount, String src) onFinish;
  const BuyerQrFlow({super.key, required this.onFinish});
  @override
  State<BuyerQrFlow> createState() => _BuyerQrFlowState();
}

class _BuyerQrFlowState extends State<BuyerQrFlow> {
  int? amount;
  String src = 'main';
  bool scannedMerchant = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت با QR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
          if (!scannedMerchant)
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.first.rawValue;
                  if (code != null) {
                    final data = jsonDecode(code);
                    if (data['type'] == 'ask') {
                      amount = data['amount'];
                      setState(() => scannedMerchant = true);
                    }
                  }
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    const Text('این QR را به فروشنده نشان بده'),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: jsonEncode({
                        'type': 'confirm',
                        'amount': amount,
                        'src': src,
                        'time': DateTime.now().toIso8601String()
                      }),
                      size: 220,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                        onPressed: () {
                          widget.onFinish(amount!, src);
                          Navigator.pop(context);
                        },
                        child: const Text('پایان و بازگشت')),
                  ],
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
