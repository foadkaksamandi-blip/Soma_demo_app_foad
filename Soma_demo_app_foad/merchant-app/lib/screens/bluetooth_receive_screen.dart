import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  bool _scanning = false;
  bool _connected = false;
  String _status = 'در انتظار اتصال...';
  BluetoothDevice? _device;
  BluetoothCharacteristic? _char;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوز بلوتوث لازم است.');
      return;
    }
    setState(() => _status = 'آماده برای جفت‌سازی امن.');
  }

  Future<void> _startPairing() async {
    setState(() {
      _scanning = true;
      _status = 'در حال جستجوی خریدار...';
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    final results = await FlutterBluePlus.scanResults.first;
    if (results.isEmpty) {
      setState(() {
        _scanning = false;
        _status = 'هیچ دستگاهی یافت نشد.';
      });
      return;
    }

    _device = results.first.device;
    await FlutterBluePlus.stopScan();

    try {
      await _device!.connect(timeout: const Duration(seconds: 8));
      setState(() {
        _connected = true;
        _scanning = false;
        _status = 'اتصال برقرار شد. در انتظار پرداخت...';
      });

      final services = await _device!.discoverServices();
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.properties.write || c.properties.notify) {
            _char = c;
            _listenForPayment();
            break;
          }
        }
      }
    } catch (e) {
      setState(() {
        _scanning = false;
        _status = 'اتصال ناموفق بود.';
      });
    }
  }

  void _listenForPayment() {
    _char?.setNotifyValue(true);
    _char?.value.listen((data) async {
      try {
        final payload = utf8.decode(data);
        final m = jsonDecode(payload) as Map;
        if (m['type'] == 'PAY') {
          final amount = (m['amount'] ?? 0) as int;
          final wallet = m['wallet'] ?? 'main';
          final ok = await LocalDB.instance.receiveAmount(amount, wallet);
          if (ok) {
            setState(() => _status = 'پرداخت $amount دریافت شد ✅');
          } else {
            setState(() => _status = 'خطا در ثبت پرداخت.');
          }
        }
      } catch (_) {
        setState(() => _status = 'داده دریافتی نامعتبر است.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با بلوتوث (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scanning ? null : _startPairing,
              child: const Text('شروع و جفت‌سازی امن'),
            ),
          ],
        ),
      ),
    );
  }
}
