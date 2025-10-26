import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import '../services/bluetooth_service.dart';
import '../services/qr_service.dart';
import '../services/local_db.dart';
import 'package:uuid/uuid.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  bool isScanning = false;
  BluetoothDevice? selectedDevice;
  bool secure = true;
  final uuid = const Uuid();

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  Future<void> _scanAndList() async {
    setState(() {
      isScanning = true;
    });
    final devices = await BuyerBluetoothService.instance.scanDevices();
    setState(() {
      isScanning = false;
    });
    if (devices.isEmpty) {
      _toast('هیچ دستگاهی پیدا نشد');
      return;
    }
    // ساده: نشان دادن دیالوگ انتخاب اولین دستگاه یا انتخاب از لیست
    final choice = await showDialog<BluetoothDevice?>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('انتخاب دستگاه فروشنده'),
        children: devices.map((d) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, d),
            child: Text('${d.name ?? "Unknown"} — ${d.address}'),
          );
        }).toList(),
      ),
    );
    if (choice != null) {
      setState(() => selectedDevice = choice);
    }
  }

  Future<void> _connectAndPay() async {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _toast('مبلغ را وارد کنید');
      return;
    }
    if (selectedDevice == null) {
      _toast('ابتدا دستگاه فروشنده را انتخاب کنید');
      return;
    }
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('مبلغ معتبر نیست');
      return;
    }

    final okEnable = await BuyerBluetoothService.instance.ensureEnabled();
    if (!okEnable) {
      _toast('بلوتوث روشن نیست یا اجازه داده نشده');
      return;
    }

    final connected = await BuyerBluetoothService.instance.connect(selectedDevice!.address);
    if (!connected) {
      _toast('اتصال به دستگاه موفق نشد');
      return;
    }

    final txId = 'SOMA-${DateTime.now().toIso8601String().split('T').first}-${uuid.v4().substring(0,6)}';
    final payload = BuyerQrService().buildPayload(amount: amount, txId: txId);
    final sent = await BuyerBluetoothService.instance.sendJson(payload);
    if (sent) {
      // کاهش موجودی خریدار و ثبت تراکنش
      LocalDB.instance.addBuyerBalance(-amount);
      LocalDB.instance.addBuyerTx(
        txId: txId,
        amount: amount,
        method: 'BT',
        ts: DateTime.now().millisecondsSinceEpoch,
        status: 'SUCCESS',
      );
      _showSuccess(amount, txId);
    } else {
      _toast('ارسال داده به فروشنده ناموفق بود');
    }

    await BuyerBluetoothService.instance.disconnect();
  }

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl), backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  void _showSuccess(int amount, String txId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('پرداخت موفق', textDirection: TextDirection.rtl),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مبلغ: ${_fmt(amount)} ریال'),
              const SizedBox(height: 8),
              Text('کد تراکنش: $txId'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))
        ],
      ),
    );
    _toast('پرداخت با موفقیت انجام شد', ok: true);
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        title: const Text('پرداخت با بلوتوث', textDirection: TextDirection.rtl),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTurquoise.withOpacity(0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('مبلغ پرداختی'),
                const SizedBox(height: 8),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'مثلاً ۵۰۰٬۰۰۰', border: OutlineInputBorder(), isDense: true)),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTurquoise.withOpacity(0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isScanning ? 'در حال جستجو...' : 'جستجوی دستگاه فروشنده', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ElevatedButton.icon(onPressed: isScanning ? null : _scanAndList, icon: const Icon(Icons.bluetooth_searching), label: Text(isScanning ? 'در حال جستجو...' : 'جستجوی دستگاه'), style: ElevatedButton.styleFrom(backgroundColor: primaryTurquoise, foregroundColor: Colors.white)),
                const SizedBox(height: 8),
                Text(selectedDevice == null ? 'هیچ دستگاه انتخاب نشده' : 'انتخاب شده: ${selectedDevice!.name ?? 'Unknown'} — ${selectedDevice!.address}'),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTurquoise.withOpacity(0.25))),
              child: Row(children: [
                Switch(value: secure, onChanged: (v) => setState(() => secure = v), activeColor: successGreen),
                const SizedBox(width: 8),
                const Text('اتصال ایمن'),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 48, child: ElevatedButton.icon(onPressed: _connectAndPay, icon: const Icon(Icons.check), label: const Text('پرداخت'), style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white))),
          ],
        ),
      ),
    );
  }
}
