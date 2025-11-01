import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class BluetoothPayScreen extends StatefulWidget {
  final int amount;
  const BluetoothPayScreen({super.key, required this.amount});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
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
    setState(() => _status = 'آماده برای جفت‌سازی و پرداخت.');
  }

  Future<void> _startPairing() async {
    setState(() {
      _scanning = true;
      _status = 'در حال جستجوی فروشنده...';
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
        _status = 'اتصال برقرار شد ✅ در حال ارسال مبلغ...';
      });

      final services = await _device!.discoverServices();
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.properties.write) {
            _char = c;
            _sendPayment();
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

  Future<void> _sendPayment() async {
    if (_char == null) {
      setState(() => _status = 'خطا: کانال ارتباطی یافت نشد.');
      return;
    }
    final payload = jsonEncode({
      "type": "PAY",
      "amount": widget.amount,
      "wallet": "main",
      "time": DateTime.now().toIso8601String(),
    });

    try {
      await _char!.write(utf8.encode(payload));
      await LocalDB.instance.spend_amount(widget.amount, "main");
      setState(() => _status = 'پرداخت با موفقیت انجام شد ✅');
    } catch (e) {
      setState(() => _status = 'خطا در ارسال پرداخت.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پرداخت با بلوتوث (آفلاین)')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(_status, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _scanning ? null : _startPairing,
                child: const Text('شروع پرداخت امن'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
