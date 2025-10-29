import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/local_db.dart';
import '../services/transaction_history.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selected;
  BluetoothConnection? connection;
  bool connecting = false;
  bool sending = false;
  String status = 'منتظر اتصال...';

  int amount = 0;
  String wallet = 'account';

  @override
  void initState() {
    super.initState();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    amount = (args['amount'] is int) ? args['amount'] as int : 0;
    wallet = (args['wallet'] as String?) ?? 'account';
    _scanBonded();
  }

  Future<void> _scanBonded() async {
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() => devices = bonded);
  }

  Future<void> _connect() async {
    if (selected == null) return;
    setState(() {
      connecting = true;
      status = 'در حال اتصال به ${selected!.name ?? selected!.address}...';
    });
    try {
      connection = await BluetoothConnection.toAddress(selected!.address);
      connection!.input?.listen((data) {
        final msg = utf8.decode(data);
        if (msg.trim().toUpperCase().contains('ACK')) {
          // تایید دریافت فروشنده => کسر موجودی و ثبت تراکنش
          LocalDB.instance.addBuyerBalance(-amount);
          TransactionHistoryService()
              .add(method: 'bluetooth', amount: amount, wallet: wallet);
          if (mounted) {
            setState(() => status = 'پرداخت موفق از طریق بلوتوث.');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('پرداخت موفق.')),
            );
          }
        }
      }, onDone: () {
        setState(() => status = 'ارتباط بسته شد.');
      });
      setState(() => status = 'اتصال برقرار شد. آماده پرداخت.');
    } catch (e) {
      setState(() => status = 'اتصال ناموفق.');
    } finally {
      setState(() => connecting = false);
    }
  }

  Future<void> _sendPayment() async {
    if (connection == null || !(connection!.isConnected)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('اتصال برقرار نیست.')));
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('مبلغ نامعتبر است.')));
      return;
    }
    if (LocalDB.instance.buyerBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('موجودی خریدار کافی نیست.')));
      return;
    }
    setState(() {
      sending = true;
      status = 'ارسال درخواست پرداخت...';
    });
    final payload = jsonEncode({
      'type': 'pay',
      'amount': amount,
      'wallet': wallet,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
    connection!.output.add(utf8.encode('$payload\n'));
    await connection!.output.allSent;
    setState(() {
      sending = false;
      status = 'در انتظار تایید فروشنده (ACK)...';
    });
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPay = selected != null && connection?.isConnected == true;

    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت با بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('مبلغ: $amount ریال | کیف: $wallet'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<BluetoothDevice>(
                    isExpanded: true,
                    value: selected,
                    hint: const Text('انتخاب دستگاه فروشنده (bonded)'),
                    items: devices
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('${d.name ?? 'Unknown'} (${d.address})'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                ),
                IconButton(
                  onPressed: _scanBonded,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'جستجوی دوباره دستگاه‌های جفت‌شده',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: connecting ? null : _connect,
                  icon: const Icon(Icons.bluetooth_connected),
                  label: const Text('اتصال'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: canPay && !sending ? _sendPayment : null,
                  icon: const Icon(Icons.send),
                  label: const Text('ارسال پرداخت'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('وضعیت: $status'),
            ),
            const Spacer(),
            const Text(
              'نکته: فروشنده باید صفحه «دریافت با بلوتوث» را باز نگه دارد تا ACK ارسال شود.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
