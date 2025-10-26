import 'dart:async';

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

  @override
  void initState() {
    super.initState();
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
    if (state != BluetoothAdapterState.on) {
      // در اندروید کاربر باید دستی روشن کند
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً بلوتوث را روشن کنید.')),
      );
    }
  }

  Future<void> _startScan() async {
    _results.clear();
    setState(() {});

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((list) {
      // آخرین نتایج
      setState(() {
        _results
          ..clear()
          ..addAll(list);
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
  }

  Future<void> _connectAndSend(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 8));
      // این‌جا می‌توان نوشتن روی سرویس/خصوصیت را اضافه کرد.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('اتصال به ${device.platformName} برقرار شد (دمو).')),
        );
      }
      await device.disconnect();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطا در اتصال: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          title: const Text('پرداخت با بلوتوث'),
          centerTitle: true,
          actions: [
            IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _results.isEmpty
            ? const Center(child: Text('هیچ دستگاهی پیدا نشد. جستجو را تکرار کنید.'))
            : ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = _results[i];
                  final d = r.device;
                  return ListTile(
                    title: Text(d.platformName.isEmpty ? '(بدون‌نام)' : d.platformName),
                    subtitle: Text(d.remoteId.str),
                    trailing: ElevatedButton(
                      onPressed: () => _connectAndSend(d),
                      child: const Text('اتصال'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
