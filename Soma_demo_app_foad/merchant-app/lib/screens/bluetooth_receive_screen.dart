import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../services/local_db.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  BluetoothConnection? _serverConn;
  bool _listening = false;
  String? _status;
  String? _lastMsg;

  void _show(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  Future<void> _startServer() async {
    final enabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (!(enabled ?? false)) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    setState(() {
      _listening = true;
      _status = 'در انتظار دریافت از خریدار…';
    });

    // توجه: flutter_bluetooth_serial سرور واقعی RFCOMM ندارد؛
    // در عمل باید دستگاه خریدار به فروشنده متصل شود و ما فقط
    // داده را از input بخوانیم. پس کافی است در لاجیک فروشنده
    // منتظر ورودی بمانیم؛ همین‌جا رفتار را شبیه‌سازی می‌کنیم.
    FlutterBluetoothSerial.instance.onRead?.listen((Uint8List data) {});
  }

  Future<void> _acceptFromAddress(String address) async {
    try {
      final conn = await BluetoothConnection.toAddress(address);
      setState(() {
        _serverConn = conn;
        _status = 'اتصال از خریدار برقرار شد.';
      });

      final buffer = StringBuffer();
      await for (final chunk in conn.input!.map(utf8.decode)) {
        buffer.write(chunk);
        if (buffer.toString().contains('\n')) break;
      }
      final raw = buffer.toString().trim();
      setState(() => _lastMsg = raw);

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final int amount = data['amount'] as int? ?? 0;

      if (amount > 0) {
        LocalDBMerchant.instance.addMerchantBalance(amount);
        conn.output.add(Uint8List.fromList(utf8.encode('OK\n')));
        await conn.output.allSent;
        _show('دریافت مبلغ $amount ریال از خریدار.', ok: true);
      } else {
        conn.output.add(Uint8List.fromList(utf8.encode('ERR\n')));
        await conn.output.allSent;
      }

      await conn.close();
      setState(() {
        _serverConn = null;
        _status = 'پایان ارتباط.';
      });
    } catch (e) {
      _show('خطا در دریافت: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);

    return const Directionality(
      textDirection: TextDirection.rtl,
      child: _BluetoothReceiveBody(),
    );
  }
}

class _BluetoothReceiveBody extends StatefulWidget {
  const _BluetoothReceiveBody();

  @override
  State<_BluetoothReceiveBody> createState() => _BluetoothReceiveBodyState();
}

class _BluetoothReceiveBodyState extends State<_BluetoothReceiveBody> {
  bool _listening = false;
  String? _status;

  void _show(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  Future<void> _start() async {
    final enabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (!(enabled ?? false)) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    setState(() {
      _listening = true;
      _status = 'برای دریافت، خریدار باید اتصال را برقرار کند…';
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دریافت با بلوتوث'),
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _listening ? null : _start,
              icon: const Icon(Icons.bluetooth_connected),
              label: const Text('آماده دریافت'),
            ),
            const SizedBox(height: 12),
            if (_status != null) Text(_status!),
            const SizedBox(height: 12),
            const Text('نکته: ابتدا دستگاه‌ها را Pair کنید. در این دمو، خریدار اتصال را آغاز می‌کند و مبلغ را ارسال می‌نماید.'),
          ],
        ),
      ),
    );
  }
}
