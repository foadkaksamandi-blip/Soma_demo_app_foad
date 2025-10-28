import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/local_db.dart';
import '../services/transaction_service.dart';
import '../models/tx_log.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  bool _listening = false;
  String? _status;

  void _startAdvertising() async {
    setState(() {
      _listening = true;
      _status = 'در انتظار اتصال خریدار...';
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name.contains('SOMA')) {
          await r.device.connect();
          final log = TxLog.success(
            amount: 100000,
            source: 'عادی',
            method: 'Bluetooth',
            counterparty: 'buyer',
          );
          LocalDBMerchant.instance.addMerchantBalance(log.amount);
          setState(() {
            _status = 'دریافت  ${log.amount} ریال با موفقیت ثبت شد ✔️';
          });
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color successGreen = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          title: const Text('دریافت با بلوتوث'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('شروع به گوش دادن'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _listening ? null : _startAdvertising,
              ),
              const SizedBox(height: 16),
              if (_status != null)
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
