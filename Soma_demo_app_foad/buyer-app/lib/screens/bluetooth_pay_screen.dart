import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/local_db.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');

  bool _scanning = false;
  bool _connected = false;

  String _status = 'در انتظار اتصال';
  int _amount = 0;
  String _wallet = 'main';

  BluetoothDevice? _device;
  StreamSubscription<List<ScanResult>>? _scanSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LocalDB.instance.ensureSeed();
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      _wallet = (args['wallet'] ?? 'main') as String;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _status = 'جستجوی فروشنده...';
    });

    // Start scan for a short window
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (results.isEmpty) return;
      // Pick first available device (demo)
      final first = results.first.device;
      _device = first;

      try {
        await FlutterBluePlus.stopScan();
        setState(() => _scanning = false);

        setState(() => _status = 'اتصال به ${first.platformName} ...');
        await first.connect(timeout: const Duration(seconds: 8));
        setState(() {
          _connected = true;
          _status = 'اتصال برقرار شد';
        });
      } catch (e) {
        setState(() {
          _scanning = false;
          _connected = false;
          _status = 'اتصال ناموفق';
        });
      }
    });
  }

  Future<void> _pay() async {
    // Local deduct
    final ok = await LocalDB.instance.spend_amount(_amount, _wallet);
    if (!ok) {
      setState(() => _status = 'موجودی کیف انتخابی کافی نیست.');
      return;
    }

    // Compose demo payload (would be sent over BT in a real app)
    final txId = await LocalDB.instance.newTxId();
    final payload = jsonEncode({
      'type': 'CONFIRM',
      'txid': txId,
      'amount': _amount,
      'wallet': _wallet,
      'time': DateTime.now().toIso8601String(),
    });

    // In a real implementation we would write to a GATT characteristic here.
    // For the demo, just show as success:
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('پرداخت آفلاین'),
        content: Text('پرداخت با موفقیت انجام شد.\n$payload'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بستن'),
          )
        ],
      ),
    );
    setState(() => _status = 'پرداخت انجام شد');
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = _fmt.format(_amount);
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت بلوتوث (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_connected)
              ElevatedButton(
                onPressed: _scanning ? null : _startScan,
                child: Text(_scanning ? 'در حال جستجو...' : 'شروع و جستجوی فروشنده'),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 6),
                Text(_connected ? 'اتصال برقرار است' : 'اتصال برقرار نیست'),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('اصلی'),
                  selected: _wallet == 'main',
                  onSelected: (_) => setState(() => _wallet = 'main'),
                ),
                ChoiceChip(
                  label: const Text('یارانه‌ای'),
                  selected: _wallet == 'subsidy',
                  onSelected: (_) => setState(() => _wallet = 'subsidy'),
                ),
                ChoiceChip(
                  label: const Text('اضطراری ملی'),
                  selected: _wallet == 'emergency',
                  onSelected: (_) => setState(() => _wallet = 'emergency'),
                ),
                ChoiceChip(
                  label: const Text('رمزارز ملی'),
                  selected: _wallet == 'crypto',
                  onSelected: (_) => setState(() => _wallet = 'crypto'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('مبلغ خرید: $amountStr'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _connected && _amount > 0 ? _pay : null,
                child: const Text('پرداخت'),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _status,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
