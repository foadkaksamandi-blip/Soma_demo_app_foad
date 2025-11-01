import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

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
    // دریافت آرگومان‌ها (amount, wallet) از صفحه قبل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      _wallet = (args['wallet'] ?? 'main') as String;
      setState(() {});
    });
  }

  Future<void> _startScan() async {
    final ok = await AppPermissions.ensureBTAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوز بلوتوث لازم است.');
      return;
    }

    setState(() {
      _scanning = true;
      _status = 'در حال جستجو…';
    });

    try {
      // استفاده صحیح از API: instance.*
      await FlutterBluePlus.instance.startScan(timeout: const Duration(seconds: 6));
      final List<ScanResult> results =
          await FlutterBluePlus.instance.scanResults.first;

      await FlutterBluePlus.instance.stopScan();

      if (results.isEmpty) {
        setState(() {
          _scanning = false;
          _status = 'هیچ فروشنده‌ای یافت نشد.';
        });
        return;
      }

      // سادگی دمو: اولین دیوایس
      _device = results.first.device;

      try {
        await _device!.connect(timeout: const Duration(seconds: 8));
        setState(() {
          _connected = true;
          _scanning = false;
          _status = 'اتصال برقرار شد.';
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

  Future<void> _pay() async {
    if (!_connected) return;

    // کسر از کیف انتخاب‌شده در پایگاه محلی
    final ok = await LocalDB.instance.spendAmount(_amount, _wallet);
    if (!ok) {
      setState(() => _status = 'موجودی کیف انتخاب‌شده کافی نیست.');
      return;
    }

    // در نسخه دمو ارسال دیتا واقعی به کاراکتریستیک انجام نمی‌دهیم
    // فقط وضعیت را آپدیت می‌کنیم
    final txId = await LocalDB.instance.newTxId();
    setState(() {
      _status = 'پرداخت انجام شد. کد: $txId';
    });
  }

  @override
  void dispose() {
    // قطع اتصال در خروج
    unawaited(_device?.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پرداخت بلوتوث (آفلاین)')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('مبلغ: '),
                  Text(_fmt.format(_amount)),
                  const SizedBox(width: 12),
                  const Text('کیف: '),
                  Text(_wallet),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _scanning ? null : _startScan,
                  child: Text(_scanning ? 'در حال جستجو…' : 'شروع و جستجوی فروشنده'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(_connected ? Icons.lock_open : Icons.lock_outline,
                      color: _connected ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_status)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _connected ? _pay : null,
                  child: const Text('پرداخت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
