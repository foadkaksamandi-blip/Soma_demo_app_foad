import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fa_IR';
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Merchant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        scaffoldBackgroundColor: const Color(0xFFF2FBF5),
      ),
      home: const MerchantHome(),
    );
  }
}

class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});
  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  final _fmt = DateFormat('yyyy/MM/dd HH:mm');
  int _balance = 0;
  String _lastTx = '-';
  String _lastTime = '-';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _balance = sp.getInt('merchant.balance') ?? 0;
      _lastTx = sp.getString('merchant.lastTx') ?? '-';
      _lastTime = sp.getString('merchant.lastTime') ?? '-';
    });
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('merchant.balance', _balance);
    await sp.setString('merchant.lastTx', _lastTx);
    await sp.setString('merchant.lastTime', _lastTime);
  }

  Future<void> _applyCredit(int amount, String txid) async {
    setState(() {
      _balance += amount;
      _lastTx = txid;
      _lastTime = _fmt.format(DateTime.now());
    });
    await _persist();
  }

  void _openBt() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return BtReceivePage(onSuccess: (amount, txid) async {
        await _applyCredit(amount, 'BT-$txid');
      });
    }));
  }

  void _openQr() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return QrReceivePage(onSuccess: (amount, txid) async {
        await _applyCredit(amount, 'QR-$txid');
      });
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اپ آفلاین سوما — اپ فروشنده', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0.6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('موجودی', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('$_balance', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _openBt, child: const Text('دریافت از بلوتوث'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _openQr, child: const Text('دریافت از QR'))),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0.6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('شماره تراکنش', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_lastTx, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('زمان: $_lastTime'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============== BT RECEIVE ==============
class BtReceivePage extends StatefulWidget {
  final Future<void> Function(int amount, String txid) onSuccess;
  const BtReceivePage({super.key, required this.onSuccess});

  @override
  State<BtReceivePage> createState() => _BtReceivePageState();
}

class _BtReceivePageState extends State<BtReceivePage> {
  final _amountCtrl = TextEditingController();
  bool _secure = false;
  String _status = 'در انتظار اتصال خریدار';
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selected;

  Future<void> _advertiseAndScan() async {
    setState(() {
      _status = 'اسکن برای اتصال...';
      _devices = [];
      _selected = null;
      _secure = false;
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    final results = await FlutterBluePlus.onScanResults.first;
    await FlutterBluePlus.stopScan();
    setState(() {
      _devices = results.map((e) => e.device).toList();
      _status = _devices.isEmpty ? 'چیزی پیدا نشد' : 'دستگاه را انتخاب کنید';
    });
  }

  Future<void> _connect(BluetoothDevice d) async {
    setState(() => _status = 'اتصال...');
    try {
      await d.connect(timeout: const Duration(seconds: 5));
    } catch (_) {}
    setState(() {
      _selected = d;
      _secure = true; // شبیه‌سازی امن
      _status = 'اتصال ایمن برقرار شد';
    });
  }

  Future<void> _accept() async {
    if (!_secure) return;
    final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt <= 0) {
      setState(() => _status = 'مبلغ نامعتبر');
      return;
    }
    final txid = const Uuid().v4().substring(0, 8);
    await widget.onSuccess(amt, txid);
    if (mounted) {
      setState(() => _status = 'تراکنش موفق: BT-$txid');
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ElevatedButton(onPressed: _advertiseAndScan, child: const Text('آماده‌سازی و اسکن')),
          const SizedBox(height: 8),
          if (_devices.isNotEmpty)
            DropdownButton<BluetoothDevice>(
              isExpanded: true,
              value: _selected,
              hint: const Text('انتخاب دستگاه خریدار'),
              items: _devices
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.platformName.isEmpty ? d.remoteId.str : d.platformName)))
                  .toList(),
              onChanged: (d) => _connect(d!),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(_secure ? Icons.verified_user : Icons.lock_outline, color: _secure ? Colors.green : Colors.grey),
            const SizedBox(width: 8),
            Text(_secure ? 'اتصال ایمن' : 'در انتظار اتصال ایمن'),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _accept, child: const Text('تأیید و دریافت'))),
          const SizedBox(height: 12),
          Text('وضعیت: $_status'),
        ]),
      ),
    );
  }
}

// ============== QR RECEIVE ==============
class QrReceivePage extends StatefulWidget {
  final Future<void> Function(int amount, String txid) onSuccess;
  const QrReceivePage({super.key, required this.onSuccess});

  @override
  State<QrReceivePage> createState() => _QrReceivePageState();
}

class _QrReceivePageState extends State<QrReceivePage> {
  String _status = 'یک QR درخواست را اسکن کنید یا مبلغ بسازید';
  String? _confirmPayload; // برای نمایش تأیید به خریدار
  int _amount = 0;

  Future<void> _scanReq() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _ScanView()));
    if (code == null) return;
    try {
      final data = jsonDecode(code);
      if (data['type'] == 'PAY_REQ') {
        setState(() {
          _amount = data['amount'] ?? 0;
          _status = 'درخواست دریافت شد: $_amount';
        });
        _buildConfirm();
      } else {
        setState(() => _status = 'QR مناسب نیست');
      }
    } catch (_) {
      setState(() => _status = 'QR نامعتبر');
    }
  }

  void _buildConfirm() {
    final txid = const Uuid().v4().substring(0, 8);
    final payload = jsonEncode({'type': 'PAY_CONF', 'amount': _amount, 'txid': txid});
    setState(() => _confirmPayload = payload);
  }

  Future<void> _finalize() async {
    if (_amount <= 0) return;
    final txid = const Uuid().v4().substring(0, 8);
    await widget.onSuccess(_amount, txid);
    if (mounted) {
      setState(() => _status = 'تراکنش موفق: QR-$txid');
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('دریافت با QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _scanReq, child: const Text('اسکن QR (درخواست)'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _finalize, child: const Text('تأیید دستی و دریافت'))),
            ],
          ),
          const SizedBox(height: 12),
          if (_confirmPayload != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text('QR تأیید برای خریدار', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  QrImageView(data: _confirmPayload!, size: 220),
                  const SizedBox(height: 6),
                  const Text('خریدار این QR را اسکن می‌کند'),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          Text('وضعیت: $_status'),
        ],
      ),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن')),
      body: MobileScanner(
        onDetect: (capture) {
          final codes = capture.barcodes;
          if (codes.isNotEmpty) {
            final raw = codes.first.rawValue;
            if (raw != null) Navigator.pop(context, raw);
          }
        },
      ),
    );
  }
}
