import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';
import '../services/local_db.dart';
import 'package:intl/intl.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  bool isDiscoverable = false;
  String? lastPayload;
  BluetoothConnection? connection;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    final ok = await MerchantBluetoothService.instance.becomeDiscoverable();
    if (!ok) {
      _toast('بلوتوث فعال یا قابل‌دسترسی نیست');
      return;
    }
    setState(() => isDiscoverable = true);

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      if (state == BluetoothState.STATE_OFF) {
        _toast('بلوتوث خاموش شد');
        setState(() => isDiscoverable = false);
      }
    });

    FlutterBluetoothSerial.instance
        .acceptIncomingConnection('SOMA-Merchant')
        .then((conn) async {
      await MerchantBluetoothService.instance.setConnection(conn);
      connection = conn;
      _listenIncoming();
    }).catchError((e) {
      _toast('اتصال ورودی شکست خورد: $e');
    });
  }

  void _listenIncoming() {
    MerchantBluetoothService.instance.inboundLines?.listen((line) {
      setState(() => lastPayload = line);
      try {
        final json = jsonDecode(line);
        if (json is Map && json['amount'] != null && json['tx_id'] != null) {
          final int amount = json['amount'];
          final String txId = json['tx_id'];
          LocalDBMerchant.instance.addMerchantBalance(amount);
          LocalDBMerchant.instance.addMerchantTx(
            txId: txId,
            amount: amount,
            method: 'BT',
            ts: DateTime.now().millisecondsSinceEpoch,
            status: 'SUCCESS',
          );
          _toast('تراکنش دریافت شد: +${_fmt(amount)} ریال', ok: true);
        }
      } catch (_) {
        _toast('داده‌ی نامعتبر دریافت شد');
      }
    });
  }

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87,
      ),
    );
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دریافت با بلوتوث', textDirection: TextDirection.rtl),
        backgroundColor: successGreen,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryTurquoise.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDiscoverable
                        ? 'دستگاه قابل شناسایی است و منتظر اتصال خریدار...'
                        : 'در انتظار فعال‌سازی بلوتوث',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (lastPayload != null) ...[
                    const Divider(),
                    const Text('آخرین داده دریافت‌شده:'),
                    const SizedBox(height: 8),
                    Text(lastPayload!, style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
