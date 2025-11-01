import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import '../services/bluetooth_service.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  final _bt = MerchantBluetoothService();

  bool _ready = false;
  String? _status;
  String? _lastTx;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final ok = await AppPermissions.ensureBtAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوزها لازم است.');
      return;
    }
    setState(() => _ready = true);
  }

  Future<void> _listen() async {
    setState(() => _status = 'درحال انتظار دریافت...');
    await for (final dev in FlutterBluePlus.connectedDevices) {
      await _bt.attachToCharacteristic(dev);
    }
    _bt.onPayments().listen((m) async {
      final amount = m['amount'] as int;
      await LocalDBMerchant.instance.add(amount);
      setState(() {
        _lastTx = m['txId'] as String?;
        _status = 'دریافت موفق: ${_fmt.format(amount)} ریال';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دریافت با بلوتوث')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _ready ? _listen : null,
                icon: const Icon(Icons.sensors),
                label: const Text('شروع دریافت'),
              ),
              const SizedBox(height: 12),
              if (_status != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_status!, textAlign: TextAlign.center),
                ),
              const Spacer(),
              if (_lastTx != null) Text('آخرین کد تراکنش: $_lastTx'),
            ],
          ),
        ),
      ),
    );
  }
}
