import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final List<ScanResult> _results = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _isScanning = false;

  int _amount = 0;
  String _source = 'یارانه';

  @override
  void initState() {
    super.initState();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _amount = (args['amount'] as int?) ?? 0;
    _source = (args['source'] as String?) ?? 'یارانه';
    _ensureBluetoothOn();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _ensureBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً بلوتوث را روشن کنید')),
      );
    }
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    _results.clear();
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((list) {
      setState(() {
        _results
          ..clear()
          ..addAll(list);
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connectAndSend(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 8));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اتصال به «${device.platformName.isEmpty ? 'نامشخص' : device.platformName}» برقرار شد')),
      );

      // ساخت payload
      final payload = 'SOMA|BUYER|AMOUNT=$_amount|SOURCE=$_source|TS=${DateTime.now().millisecondsSinceEpoch}';
      final bytes = utf8.encode(payload);

      // تلاش برای نوشتن روی characteristic قابل‌نوشتن
      final services = await device.discoverServices();
      BluetoothCharacteristic? writable;
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            writable = c;
            break;
          }
        }
        if (writable != null) break;
      }

      if (writable != null) {
        await writable!.write(bytes, withoutResponse: writable!.properties.writeWithoutResponse);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('داده پرداخت ارسال شد')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Characteristic مناسب برای ارسال پیدا نشد (دمو اتصال انجام شد)')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اتصال/ارسال: $e')),
      );
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('پرداخت با بلوتوث'),
        centerTitle: true,
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isScanning
            ? const Center(child: CircularProgressIndicator())
            : _results.isEmpty
                ? const Center(child: Text('هیچ دستگاهی پیدا نشد. جستجو را تکرار کنید.'))
                : ListView.separated(
                    itemBuilder: (ctx, i) {
                      final r = _results[i];
                      final d = r.device;
                      return ListTile(
                        title: Text(d.platformName.isEmpty ? '(ناشناس)' : d.platformName),
                        subtitle: Text(d.remoteId.str),
                        trailing: ElevatedButton(
                          onPressed: () => _connectAndSend(d),
                          child: const Text('ارسال'),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: _results.length,
                  ),
      ),
    );
  }
}
