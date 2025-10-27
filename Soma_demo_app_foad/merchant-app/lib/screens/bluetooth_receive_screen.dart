import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  final List<ScanResult> _results = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  bool _scanning = false;

  String _amountFromArgs(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final amount = (args['amount'] ?? '').toString();
    return amount;
  }

  Future<void> _ensureOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      // تلاش برای روشن کردن (در اندروید ممکن است کار نکند و باید کاربر روشن کند)
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
    }
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    _results.clear();

    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((list) {
      for (final r in list) {
        final i = _results.indexWhere((e) => e.device.remoteId == r.device.remoteId);
        if (i == -1) {
          _results.add(r);
        } else {
          _results[i] = r;
        }
      }
      if (mounted) setState(() {});
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    if (mounted) setState(() => _scanning = false);
  }

  @override
  void initState() {
    super.initState();
    _ensureOn().then((_) => _startScan());
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _receiveFrom(ScanResult r) async {
    // برای دمو: اتصال واقعی لازم نیست. فقط اسکن → انتخاب دستگاه → تایید دریافت.
    // اگر بعداً اتصال GATT خواستی، اینجا انجام بده.
    await FlutterBluePlus.stopScan();
    if (!mounted) return;

    final amount = _amountFromArgs(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('دریافت پرداخت'),
        content: Text(
          'از دستگاه: ${r.device.platformName.isEmpty ? r.device.remoteId.str : r.device.platformName}\n'
          'مبلغ: $amount',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // بستن دیالوگ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('پرداخت با بلوتوث دریافت شد.')),
              );
              Navigator.pop(context, {'ok': true}); // برگشت به صفحه قبل
            },
            child: const Text('تایید دریافت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountFromArgs(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دریافت با بلوتوث (دمو)'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _startScan,
          label: Text(_scanning ? 'درحال اسکن…' : 'اسکن دوباره'),
          icon: const Icon(Icons.bluetooth_searching),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.payments),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('مبلغ تراکنش: $amount',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('هیچ دستگاهی پیدا نشد. اسکن را تکرار کنید.'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        final title =
                            r.device.platformName.isEmpty ? r.device.remoteId.str : r.device.platformName;
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.bluetooth)),
                          title: Text(title),
                          subtitle: Text(r.device.remoteId.str),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => _receiveFrom(r),
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
