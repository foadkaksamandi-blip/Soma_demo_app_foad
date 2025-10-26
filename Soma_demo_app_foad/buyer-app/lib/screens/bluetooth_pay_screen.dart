import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';

import '../services/local_db.dart';

class BluetoothPayScreen extends StatefulWidget {
  final int enteredAmountRials;
  const BluetoothPayScreen({super.key, this.enteredAmountRials = 0});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final FlutterBluePlus _blue = FlutterBluePlus.instance;
  BluetoothDevice? _selected;
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  String? _txId;

  @override
  void initState() {
    super.initState();
    _blue.state.listen((s) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _scan() async {
    setState(() => _selected = null);
    await _blue.startScan(timeout: const Duration(seconds: 6));
    // منتظر پایان اسکن
    await Future.delayed(const Duration(seconds: 6));
    await _blue.stopScan();

    // انتخاب ساده: اولین دیوایس با نام قابل‌قبول
    final results = await _blue.scanResults.first;
    final match = results.map((e) => e.device).firstWhere(
          (d) => (d.platformName.isNotEmpty || d.remoteId.str.isNotEmpty),
          orElse: () => BluetoothDevice.fromId(''),
        );

    if (match.remoteId.str.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('دستگاهی یافت نشد')));
      return;
    }
    setState(() => _selected = match);
  }

  Future<void> _connectAndPay() async {
    if (_selected == null) return;

    try {
      await _selected!.connect(timeout: const Duration(seconds: 10));
      setState(() => _state = BluetoothConnectionState.connected);

      // در دمو: فقط تراکنش را روی دیوایس محلی ثبت می‌کنیم
      final amount = widget.enteredAmountRials > 0
          ? widget.enteredAmountRials
          : 10000; // اگر کاربر وارد نکرد
      if (LocalDB.instance.buyerBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موجودی کافی نیست')),
        );
        return;
      }

      // کسر از خریدار، افزودن به فروشنده
      LocalDB.instance.addBuyerBalance(-amount);
      LocalDB.instance.addMerchantBalance(amount);

      // شناسه تراکنش
      _txId = const Uuid().v4();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('پرداخت موفق. کد تراکنش: $_txId'),
            backgroundColor: const Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اتصال: $e')),
      );
    } finally {
      await _selected?.disconnect();
      setState(() => _state = BluetoothConnectionState.disconnected);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1ABC9C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پرداخت با بلوتوث'),
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.search),
                label: const Text('اسکن دستگاه‌ها'),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.bluetooth),
                title: Text(_selected?.platformName.isNotEmpty == true
                    ? _selected!.platformName
                    : (_selected?.remoteId.str ?? 'دستگاه انتخاب نشده')),
                subtitle: Text('وضعیت اتصال: $_state'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selected == null ? null : _connectAndPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('پرداخت'),
              ),
              if (_txId != null) ...[
                const SizedBox(height: 12),
                SelectableText('کد تراکنش: $_txId'),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
