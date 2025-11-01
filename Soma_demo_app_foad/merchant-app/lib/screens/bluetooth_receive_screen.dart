import 'dart:ui' show TextDirection;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');

  int _amount = 0;
  String _status = 'در انتظار اتصال';
  bool _scanning = false;
  bool _connected = false;

  BluetoothDevice? _device;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      setState(() {});
    });
  }

  Future<void> _startAndPair() async {
    setState(() {
      _scanning = true;
      _status = 'جستجو برای خریدار...';
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    final results = await FlutterBluePlus.scanResults.first;
    final r = results.where((e) => e.device.platformName.isNotEmpty).toList();
    await FlutterBluePlus.stopScan();

    if (r.isEmpty) {
      setState(() {
        _scanning = false;
        _status = 'هیچ دستگاهی پیدا نشد';
      });
      return;
    }

    _device = r.first.device;
    try {
      await _device!.connect(timeout: const Duration(seconds: 8));
      setState(() {
        _connected = true;
        _scanning = false;
        _status = 'اتصال برقرار شد — آماده دریافت ${_fmt.format(_amount)} تومان';
      });
    } catch (_) {
      setState(() {
        _scanning = false;
        _status = 'اتصال ناموفق';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دریافت با بلوتوث')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مبلغ دریافتی از خریدار: ${_fmt.format(_amount)} تومان'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _scanning || _connected ? null : _startAndPair,
                child: const Text('شروع و جفت‌سازی امن'),
              ),
              const SizedBox(height: 8),
              Text(_status),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تأیید دریافت'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
