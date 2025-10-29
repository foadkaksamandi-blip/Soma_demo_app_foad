import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/transaction_service.dart';

class BluetoothPayScreen extends StatefulWidget {
  final double amount;
  final String source;
  final TransactionService tx;

  const BluetoothPayScreen({
    super.key,
    required this.amount,
    required this.source,
    required this.tx,
  });

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final _found = <ScanResult>[];
  StreamSubscription<List<ScanResult>>? _sub;
  bool _scanning = false;
  bool _connected = false;
  BluetoothDevice? _device;

  Color get _primary => const Color(0xFF1ABC9C);
  Color get _success => const Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _found.clear();
      _scanning = true;
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    _sub = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _found
          ..clear()
          ..addAll(results);
      });
    });
    await Future.delayed(const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
    setState(() => _scanning = false);
  }

  Future<void> _connect(BluetoothDevice d) async {
    try {
      await d.connect(autoConnect: false);
      setState(() {
        _device = d;
        _connected = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اتصال امن برقرار شد — آماده پرداخت')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اتصال ناموفق — دوباره تلاش کنید')),
        );
      }
    }
  }

  Future<void> _pay() async {
    // در این نسخه، پس از اتصال، تراکنش محلی اعمال می‌شود.
    final ok = widget.tx.processBluetoothPayment(widget.amount);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موجودی کافی نیست')),
      );
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _success,
          content: Text('تراکنش موفق — ${widget.amount.toInt()} ریال پرداخت شد'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('پرداخت با بلوتوث'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('مبلغ: ${widget.amount.toInt()} ریال',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(_scanning ? 'در حال اسکن…' : 'اسکن دوباره'),
                    onPressed: _scanning ? null : _startScan,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _found.isEmpty
                    ? const Center(child: Text('دستگاهی پیدا نشد'))
                    : ListView.builder(
                        itemCount: _found.length,
                        itemBuilder: (_, i) {
                          final r = _found[i];
                          final name = r.device.platformName.isNotEmpty
                              ? r.device.platformName
                              : r.device.remoteId.str;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth),
                              title: Text(name),
                              subtitle: Text('RSSI: ${r.rssi}'),
                              trailing: ElevatedButton(
                                onPressed: () => _connect(r.device),
                                child: const Text('اتصال'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _connected ? _success : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _connected ? _pay : null,
                  label: const Text('پرداخت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
