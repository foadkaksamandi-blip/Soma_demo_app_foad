import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/local_db.dart';
import '../services/transaction_service.dart';
import '../models/tx_log.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  bool _connected = false;
  String? _status;
  final TextEditingController _amountCtrl = TextEditingController();
  String _source = 'عادی';
  BluetoothDevice? _device;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _scanAndConnect() async {
    setState(() {
      _status = 'در حال جستجوی دستگاه...';
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) async {
      for (var r in results) {
        if (r.device.name.contains('SOMA')) {
          FlutterBluePlus.stopScan();
          _device = r.device;
          await _device!.connect();
          setState(() {
            _connected = true;
            _status = 'اتصال ایمن برقرار شد ✔️';
          });
          break;
        }
      }
    });
  }

  void _performPayment() {
    final amt = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amt <= 0) return;

    LocalDB.instance.addToWallet(_source, -amt);
    final log = TxLog.success(
      amount: amt,
      source: _source,
      method: 'Bluetooth',
      counterparty: 'merchant',
    );
    final payload = TransactionService.buildMerchantConfirm(log: log);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'پرداخت ${amt} ریال از کیف $_source انجام شد.\nکد: ${log.id}',
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.green,
      ),
    );

    setState(() => _status = payload);
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          title: const Text('پرداخت با بلوتوث'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth),
                label: const Text('اتصال بلوتوث'),
                onPressed: _scanAndConnect,
              ),
              const SizedBox(height: 12),
              if (_status != null)
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 24),
              const Text('انتخاب کیف پول'),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('عادی'),
                    selected: _source == 'عادی',
                    onSelected: (_) => setState(() => _source = 'عادی'),
                  ),
                  ChoiceChip(
                    label: const Text('یارانه'),
                    selected: _source == 'یارانه',
                    onSelected: (_) => setState(() => _source = 'یارانه'),
                  ),
                  ChoiceChip(
                    label: const Text('اضطراری'),
                    selected: _source == 'اضطراری',
                    onSelected: (_) => setState(() => _source = 'اضطراری'),
                  ),
                  ChoiceChip(
                    label: const Text('رمز ارز ملی'),
                    selected: _source == 'رمز ارز ملی',
                    onSelected: (_) => setState(() => _source = 'رمز ارز ملی'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ پرداخت (ریال)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('انجام پرداخت'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _connected ? _performPayment : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
