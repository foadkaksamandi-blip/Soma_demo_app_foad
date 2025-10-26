import 'dart:async';
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
  StreamSubscription<List<ScanResult>>? _scanSub;
  BluetoothDevice? _selected;
  String? _txId;

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    // گوش‌دادن به نتایج اسکن
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty && mounted) {
        setState(() {
          _selected = results.first.device;
        });
      }
    });

    // شروع اسکن (API استاتیک)
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    await Future.delayed(const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
  }

  Future<void> _connectAndPay() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('هیچ دستگاهی انتخاب نشده')));
      return;
    }

    try {
      await _selected!.connect(timeout: const Duration(seconds: 10));

      final amount =
          widget.enteredAmountRials > 0 ? widget.enteredAmountRials : 10000;

      if (LocalDB.instance.buyerBalance < amount) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('موجودی کافی نیست')));
        return;
      }

      LocalDB.instance.addBuyerBalance(-amount);
      LocalDB.instance.addMerchantBalance(amount);
      _txId = const Uuid().v4();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پرداخت موفق انجام شد'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطا در اتصال: $e')));
    } finally {
      await _selected?.disconnect();
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
            children: [
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('اسکن دستگاه‌ها'),
              ),
              const SizedBox(height: 12),
              if (_selected != null)
                ListTile(
                  title: Text(
                    _selected!.platformName.isNotEmpty
                        ? _selected!.platformName
                        : _selected!.remoteId.str,
                  ),
                  subtitle: const Text('دستگاه انتخاب‌شده'),
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
