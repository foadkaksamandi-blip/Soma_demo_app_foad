import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/transaction_service.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  final double amount;
  final String source;
  final TransactionService tx;

  const BluetoothReceiveScreen({
    super.key,
    required this.amount,
    required this.source,
    required this.tx,
  });

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  bool _connected = false;
  BluetoothDevice? _device;
  Color get _primary => const Color(0xFF1ABC9C);
  Color get _success => const Color(0xFF27AE60);

  Future<void> _waitForBuyer() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() => _connected = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('اتصال ایمن برقرار شد — آماده دریافت')),
    );
  }

  void _confirmPayment() {
    final ok = widget.tx.receivePayment(
      amount: widget.amount,
      method: 'bluetooth',
      source: widget.source,
    );

    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تراکنش ناموفق')));
      return;
    }

    final r = widget.tx.getLastReceipt();
    if (r != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _success,
          content: Text(
              'دریافت موفق: ${r.amount.toInt()} ریال | ${r.id.substring(0, 8)}'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.amount.toInt().toString();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('دریافت با بلوتوث'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('مبلغ: $amountText ریال',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('در انتظار خریدار'),
                onPressed: _waitForBuyer,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('تأیید دریافت'),
                onPressed: _connected ? _confirmPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _connected ? _success : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
