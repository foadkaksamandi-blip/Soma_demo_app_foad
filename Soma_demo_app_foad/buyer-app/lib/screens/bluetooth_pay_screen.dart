import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:uuid/uuid.dart';

import '../services/local_db.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  BluetoothDevice? _selected;
  BluetoothConnection? _connection;
  bool _busy = false;
  String? _status;
  String? _txnId;

  void _show(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  Future<void> _ensureBtOn() async {
    final enabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (!(enabled ?? false)) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
  }

  Future<void> _loadBonded() async {
    await _ensureBtOn();
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    if (bonded.isEmpty) {
      _show('هیچ دستگاه جفت‌شده‌ای پیدا نشد. ابتدا دستگاه فروشنده را Pair کنید.');
      return;
    }
    final dev = await showModalBottomSheet<BluetoothDevice>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          children: bonded
              .map((d) => ListTile(
                    title: Text(d.name ?? d.address),
                    subtitle: Text(d.address),
                    onTap: () => Navigator.pop(context, d),
                  ))
              .toList(),
        ),
      ),
    );
    if (dev != null) setState(() => _selected = dev);
  }

  Future<void> _pay() async {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount <= 0) {
      _show('مبلغ را وارد کنید.');
      return;
    }
    if (_selected == null) {
      _show('ابتدا دستگاه فروشنده را انتخاب کنید.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'در حال اتصال به ${_selected!.name ?? _selected!.address}';
    });

    try {
      _connection = await BluetoothConnection.toAddress(_selected!.address);
      setState(() => _status = 'اتصال ایمن برقرار شد.');

      final payload = jsonEncode({
        'type': 'soma_payment',
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _connection!.output.add(Uint8List.fromList(utf8.encode('$payload\n')));
      await _connection!.output.allSent;

      // منتظر پاسخ OK
      final buffer = StringBuffer();
      await for (final data in _connection!.input!.map(utf8.decode)) {
        buffer.write(data);
        if (buffer.toString().contains('\n')) break;
      }
      final resp = buffer.toString().trim();
      if (resp == 'OK') {
        LocalDB.instance.addBuyerBalance(-amount);
        final id = const Uuid().v4();
        setState(() => _txnId = id);
        _show('پرداخت موفق. کد تراکنش: $id', ok: true);
      } else {
        _show('پاسخ نامعتبر از فروشنده: $resp');
      }
    } catch (e) {
      _show('خطا در اتصال/پرداخت: $e');
    } finally {
      await _connection?.close();
      _connection = null;
      setState(() {
        _busy = false;
        _status = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پرداخت با بلوتوث'),
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text('مبلغ پرداخت'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'مثلاً ۵۰۰۰۰۰',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadBonded,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(_selected == null
                    ? 'انتخاب دستگاه فروشنده'
                    : (_selected!.name ?? _selected!.address)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _busy ? null : _pay,
                icon: const Icon(Icons.send),
                label: const Text('پرداخت'),
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!),
              ],
              if (_txnId != null) ...[
                const SizedBox(height: 12),
                Text('کد تراکنش: $_txnId'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
