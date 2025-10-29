import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/transaction_service.dart';

class ReceiveBluetoothScreen extends StatefulWidget {
  final double amount;
  final TransactionService tx;

  const ReceiveBluetoothScreen({
    super.key,
    required this.amount,
    required this.tx,
  });

  @override
  State<ReceiveBluetoothScreen> createState() => _ReceiveBluetoothScreenState();
}

class _ReceiveBluetoothScreenState extends State<ReceiveBluetoothScreen> {
  bool _listening = false;
  bool _connected = false;
  BluetoothDevice? _device;
  final List<ScanResult> _found = [];

  Color get _primary => const Color(0xFF27AE60);
  Color get _success => const Color(0xFF1ABC9C);

  Future<void> _scan() async {
    setState(() {
      _listening = true;
      _found.clear();
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    FlutterBluePlus.scanResults.listen((res) {
      setState(() {
        _found
          ..clear()
          ..addAll(res);
      });
    });
    await Future.delayed(const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
    setState(() => _listening = false);
  }

  Future<void> _connect(BluetoothDevice d) async {
    try {
      await d.connect(autoConnect: false);
      setState(() {
        _device = d;
        _connected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتصال امن برقرار شد — آماده دریافت')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اتصال ناموفق — دوباره تلاش کنید')),
      );
    }
  }

  void _confirmReceive() {
    widget.tx.merchantBalance += widget.amount;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _success,
        content: Text('تراکنش دریافت شد — ${widget.amount.toInt()} ریال اضافه شد'),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('دریافت از طریق بلوتوث'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Text('مبلغ: ${widget.amount.toInt()} ریال'),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(_listening ? 'در حال اسکن...' : 'جستجو'),
                    onPressed: _listening ? null : _scan,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _found.isEmpty
                    ? const Center(child: Text('هیچ دستگاهی یافت نشد'))
                    : ListView.builder(
                        itemCount: _found.length,
                        itemBuilder: (_, i) {
                          final r = _found[i];
                          final name = r.device.platformName.isNotEmpty
                              ? r.device.platformName
                              : r.device.remoteId.str;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth),
                              title: Text(name),
                              subtitle: Text('RSSI: ${r.rssi}'),
                              trailing: ElevatedButton(
                                onPressed: () => _connect(r.device),
                                child: const Text('اتصال'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _connected ? _success : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _connected ? _confirmReceive : null,
                  label: const Text('تأیید دریافت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
