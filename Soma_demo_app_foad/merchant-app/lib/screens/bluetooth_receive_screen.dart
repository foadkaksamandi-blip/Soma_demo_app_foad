import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/local_db.dart';

/// صفحهٔ دریافت پرداخت از طریق بلوتوث
/// - فروشنده یکی از دستگاه‌های جفت‌شده (Buyer) را انتخاب می‌کند و اتصال می‌زند.
/// - پس از دریافت JSON با type=pay، اگر مبلغ معتبر بود موجودی فروشنده افزایش می‌یابد و ACK بازگردانده می‌شود.
///
/// توجه: در بعضی گوشی‌ها اتصال Classic RFCOMM بین دو موبایل محدودیت دارد.
/// اگر اتصال برقرار نشد، ابتدا دستگاه‌ها را Bond کنید و بلوتوث فروشنده را Discoverable کنید.
class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selected;
  BluetoothConnection? connection;
  String status = 'منتظر اتصال...';

  @override
  void initState() {
    super.initState();
    _scanBonded();
  }

  Future<void> _scanBonded() async {
    final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() => devices = bonded);
  }

  Future<void> _connect() async {
    if (selected == null) return;
    setState(() => status = 'در حال اتصال به ${selected!.name ?? selected!.address}...');
    try {
      connection = await BluetoothConnection.toAddress(selected!.address);
      connection!.input?.listen((data) async {
        final msg = utf8.decode(data).trim();
        // پیام‌ها می‌توانند چندتایی بیایند؛ ساده‌سازی: خط‌-محور
        for (final line in msg.split('\n')) {
          if (line.isEmpty) continue;
          try {
            final Map<String, dynamic> json = jsonDecode(line);
            if (json['type'] == 'pay') {
              final int amount = (json['amount'] is int)
                  ? json['amount'] as int
                  : int.tryParse('${json['amount']}') ?? 0;
              if (amount > 0) {
                LocalDBMerchant.instance.addMerchantBalance(amount);
                // بازگشت تایید به خریدار
                connection!.output.add(utf8.encode('ACK\n'));
                await connection!.output.allSent;
                if (mounted) {
                  setState(() => status = 'پرداخت دریافت شد: $amount ریال');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('پرداخت دریافت شد: $amount ریال')),
                  );
                }
              }
            }
          } catch (_) {
            // نادیده بگیر
          }
        }
      }, onDone: () {
        setState(() => status = 'ارتباط بسته شد.');
      });
      setState(() => status = 'اتصال برقرار شد. منتظر پرداخت...');
    } catch (e) {
      setState(() => status = 'اتصال ناموفق.');
    }
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<BluetoothDevice>(
                    isExpanded: true,
                    value: selected,
                    hint: const Text('انتخاب دستگاه خریدار (bonded)'),
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
                  tooltip: 'جستجوی دوباره',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _connect,
              icon: const Icon(Icons.bluetooth_connected),
              label: const Text('اتصال'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('وضعیت: $status'),
            ),
            const Spacer(),
            const Text(
              'نکته: اگر اتصال برقرار نشد، ابتدا دستگاه‌ها را Pair کنید و بلوتوث فروشنده را Discoverable نگه دارید.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
