import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/bluetooth_service.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class BluetoothPayScreen extends StatefulWidget {
  const BluetoothPayScreen({super.key});

  @override
  State<BluetoothPayScreen> createState() => _BluetoothPayScreenState();
}

class _BluetoothPayScreenState extends State<BluetoothPayScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  final _bt = BuyerBluetoothService();

  bool _connecting = false;
  bool _secure = false;
  String? _status;
  String? _txId;
  late int _amount;
  late String _wallet;

  @override
  void initState() {
    super.initState();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _amount = (args['amount'] ?? 0) as int;
    _wallet = (args['wallet'] ?? 'main') as String;
  }

  @override
  void dispose() {
    _bt.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() { _status = null; _connecting = true; });
    final ok = await AppPermissions.ensureBtAndCamera();
    if (!ok) {
      setState(() { _connecting = false; _status = 'مجوزهای بلوتوث/مکان/دوربین لازم است.'; });
      return;
    }
    final connected = await _bt.connectFirstMerchant();
    setState(() {
      _connecting = false;
      _secure = connected;
      _status = connected ? 'اتصال ایمن برقرار شد.' : 'فروشنده یافت نشد.';
    });
  }

  Future<void> _pay() async {
    final ok = await LocalDB.instance.spend(_amount, wallet: _wallet);
    if (!ok) {
      setState(() { _status = 'موجودی کافی نیست.'; });
      return;
    }
    final txId = LocalDB.instance.newTxId();
    final sent = await _bt.sendPayment(amount: _amount, wallet: _wallet, txId: txId);
    setState(() { _txId = sent ? txId : null; _status = sent ? 'تراکنش موفق' : 'ارسال ناموفق'; });
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پرداخت با بلوتوث')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _row('مبلغ', _fmt.format(_amount)),
              const SizedBox(height: 12),
              _row('کیف پول', _walletFa(_wallet)),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _connecting ? null : _start,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(_connecting ? 'در حال اتصال...' : 'شروع'),
              ),

              const SizedBox(height: 12),
              if (_secure)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: green.withOpacity(0.3)),
                  ),
                  child: const Text('اتصال ایمن ✅', textAlign: TextAlign.center),
                ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _secure ? _pay : null,
                icon: const Icon(Icons.payments),
                label: const Text('پرداخت'),
              ),

              const SizedBox(height: 16),
              if (_status != null) Text(_status!, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_txId != null)
                _receiptBox(txId: _txId!, method: 'Bluetooth', amount: _fmt.format(_amount)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Row(
        children: [
          Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(v, textAlign: TextAlign.left)),
        ],
      );

  String _walletFa(String w) {
    switch (w) {
      case 'subsidy': return 'موجودی یارانه';
      case 'emergency': return 'موجودی اضطراری ملی';
      case 'cbdc': return 'موجودی کیف پول رمز ارز ملی';
      default: return 'موجودی حساب اصلی';
    }
  }

  Widget _receiptBox({required String txId, required String method, required String amount}) {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('کد تراکنش: $txId'),
          Text('نحوه پرداخت: $method'),
          Text('مبلغ: $amount ریال'),
          Text('زمان: ${now.year}/${now.month}/${now.day} - ${now.hour}:${now.minute.toString().padLeft(2,'0')}'),
        ],
      ),
    );
  }
}
