import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/permissions.dart';
import '../services/local_db.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');

  bool _scanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;
  final List<ScanResult> _results = [];

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) return;

    setState(() {
      _scanning = true;
      _results.clear();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    _scanSub = FlutterBluePlus.scanResults.listen((list) {
      setState(() {
        _results
          ..clear()
          ..addAll(list);
      });
    });

    await Future.delayed(const Duration(seconds: 10));
    await FlutterBluePlus.stopScan();
    setState(() => _scanning = false);
  }

  Future<void> _receiveDemo(ScanResult r) async {
    // دمو: فقط افزایش موجودی نمایشی برای تست
    await LocalDBMerchant.instance.addIncome(wallet: 'main', amount: 100000);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('دریافت نمایشی از ${r.device.platformName} — +۱۰۰٬۰۰۰ ریال')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bal = _fmt.format(LocalDBMerchant.instance.merchantBalance);
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('موجودی فعلی: $bal ریال'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _scanning ? null : _startScan,
              child: const Text('جستجو برای خریدار'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('در انتظار اتصال'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (c, i) {
                        final r = _results[i];
                        final name = r.device.platformName.isNotEmpty ? r.device.platformName : r.device.remoteId.str;
                        return ListTile(
                          title: Text(name),
                          subtitle: Text('RSSI: ${r.rssi}'),
                          trailing: ElevatedButton(onPressed: () => _receiveDemo(r), child: const Text('دریافت')),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
