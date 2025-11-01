import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
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
  BluetoothCharacteristic? _char;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      _wallet = (args['wallet'] ?? 'main') as String;
      setState(() {});
    });
  }

  Future<bool> _ensureBTAndCamera() async {
    final req = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final ok = req.values.every((s) => s.isGranted);
    if (!ok) setState(() => _status = 'مجوز بلوتوث لازم است');
    return ok;
  }

  Future<void> _startScan() async {
    if (!await _ensureBTAndCamera()) return;
    setState(() {
      _scanning = true;
      _status = 'جستجو…';
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      final results = await FlutterBluePlus.scanResults.first;
      final r = results.where((e) => (e.device.platformName).isNotEmpty).toList();
      await FlutterBluePlus.stopScan();

      if (r.isEmpty) {
        setState(() {
          _scanning = false;
          _status = 'هیچ فروشنده‌ای یافت نشد';
        });
        return;
      }

      _device = r.first.device;
      try {
        await _device!.connect(timeout: const Duration(seconds: 8));
        setState(() {
          _connected = true;
          _scanning = false;
          _status = 'اتصال برقرار شد';
        });
      } catch (e) {
        setState(() {
          _scanning = false;
          _status = 'اتصال ناموفق';
        });
      }
    } catch (e) {
      setState(() {
        _scanning = false;
        _status = 'خطا در اسکن';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت بلوتوث (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _scanning ? null : _startScan,
              child: const Text('شروع و جستجوی فروشنده'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.lock_outline, size: 16, color: Colors.red),
              const SizedBox(width: 6),
              Text(_connected ? 'اتصال امن برقرار است' : 'اتصال برقرار نیست'),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('اصلی'), selected: _wallet=='main', onSelected: (_) => setState(()=>_wallet='main')),
                ChoiceChip(label: const Text('یارانه‌ای'), selected: _wallet=='subsidy', onSelected: (_) => setState(()=>_wallet='subsidy')),
                ChoiceChip(label: const Text('اضطراری ملی'), selected: _wallet=='emergency', onSelected: (_) => setState(()=>_wallet='emergency')),
                ChoiceChip(label: const Text('رمزارز ملی'), selected: _wallet=='crypto', onSelected: (_) => setState(()=>_wallet='crypto')),
              ],
            ),
            const SizedBox(height: 12),
            Text('مبلغ خرید: ${_fmt.format(_amount)}'),
            const Spacer(),
            Text(_status, textDirection: TextDirection.rtl),
          ],
        ),
      ),
    );
  }
}
