import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/permissions.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      _wallet = (args['wallet'] ?? 'main') as String;
    });
  }

  Future<void> _startScan() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوز بلوتوث لازم است');
      return;
    }
    setState(() {
      _scanning = true;
      _status = 'در حال جستجو...';
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
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
  }

  Future<void> _pay() async {
    if (!_connected) return;
    final ok = await LocalDB.instance.spend(_amount, wallet: _wallet);
    setState(() {
      _status = ok ? 'پرداخت انجام شد' : 'موجودی کافی نیست';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت بلوتوث (آفلاین)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('مبلغ: ${_fmt.format(_amount)}',
                textDirection: TextDirection.rtl),
            Text('کیف: $_wallet', textDirection: TextDirection.rtl),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _scanning ? null : _startScan,
              child: const Text('شروع و جفت‌سازی امن'),
            ),
            const SizedBox(height: 12),
            Text(_status,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: _connected ? _pay : null,
              child: const Text('پرداخت'),
            ),
          ],
        ),
      ),
    );
  }
}
