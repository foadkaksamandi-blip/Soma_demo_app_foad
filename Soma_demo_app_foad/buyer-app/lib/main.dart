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
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Buyer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // سبز بانکی
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2FBF5),
      ),
      home: const BuyerHome(),
    );
  }
}

class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});
  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

enum Wallet { main, subsidy, emergency, crypto }

class _BuyerHomeState extends State<BuyerHome> {
  final _fmt = DateFormat('yyyy/MM/dd HH:mm');
  int _balanceMain = 100000;
  int _balanceSubsidy = 0;
  int _balanceEmergency = 0;
  int _balanceCrypto = 0;

  String _lastTx = '-';
  String _lastTime = '-';
  Wallet _selectedWallet = Wallet.main;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _balanceMain = sp.getInt('buyer.main') ?? 100000;
      _balanceSubsidy = sp.getInt('buyer.subsidy') ?? 0;
      _balanceEmergency = sp.getInt('buyer.emergency') ?? 0;
      _balanceCrypto = sp.getInt('buyer.crypto') ?? 0;
      _lastTx = sp.getString('buyer.lastTx') ?? '-';
      _lastTime = sp.getString('buyer.lastTime') ?? '-';
    });
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('buyer.main', _balanceMain);
    await sp.setInt('buyer.subsidy', _balanceSubsidy);
    await sp.setInt('buyer.emergency', _balanceEmergency);
    await sp.setInt('buyer.crypto', _balanceCrypto);
    await sp.setString('buyer.lastTx', _lastTx);
    await sp.setString('buyer.lastTime', _lastTime);
  }

  int get _currentBalance {
    return switch (_selectedWallet) {
      Wallet.main => _balanceMain,
      Wallet.subsidy => _balanceSubsidy,
      Wallet.emergency => _balanceEmergency,
      Wallet.crypto => _balanceCrypto,
    };
  }

  Future<void> _applyDebit(int amount) async {
    setState(() {
      switch (_selectedWallet) {
        case Wallet.main:
          _balanceMain -= amount;
          break;
        case Wallet.subsidy:
          _balanceSubsidy -= amount;
          break;
        case Wallet.emergency:
          _balanceEmergency -= amount;
          break;
        case Wallet.crypto:
          _balanceCrypto -= amount;
          break;
      }
    });
    await _persist();
  }

  void _setWallet(Wallet w) {
    setState(() => _selectedWallet = w);
  }

  Future<void> _recordTx(String txId) async {
    setState(() {
      _lastTx = txId;
      _lastTime = _fmt.format(DateTime.now());
    });
    await _persist();
  }

  // --- صفحات ---
  void _openBt() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return BtPayPage(
        currentBalance: _currentBalance,
        onSuccess: (amount, txid) async {
          await _applyDebit(amount);
          await _recordTx('BT-$txid');
        },
      );
    }));
  }

  void _openQr() {
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return QrPayPage(
        walletName: _walletName(_selectedWallet),
        currentBalance: _currentBalance,
        onSuccess: (amount, txid) async {
          await _applyDebit(amount);
          await _recordTx('QR-$txid');
        },
      );
    }));
  }

  String _walletName(Wallet w) => switch (w) {
        Wallet.main => 'موجودی اصلی',
        Wallet.subsidy => 'موجودی یارانه‌ای',
        Wallet.emergency => 'موجودی اضطراری ملی',
        Wallet.crypto => 'موجودی رمز ارز ملی',
      };

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اپ آفلاین سوما — اپ خریدار', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            title: 'موجودی',
            child: Text(
              _currentBalance.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _btn(context, 'اسکن بلوتوث', _openBt)),
              const SizedBox(width: 12),
              Expanded(child: _btn(context, 'QR کد', _openQr)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('اصلی', _selectedWallet == Wallet.main, () => _setWallet(Wallet.main)),
              _chip('یارانه‌ای', _selectedWallet == Wallet.subsidy, () => _setWallet(Wallet.subsidy)),
              _chip('اضطراری ملی', _selectedWallet == Wallet.emergency, () => _setWallet(Wallet.emergency)),
              _chip('رمز ارز ملی', _selectedWallet == Wallet.crypto, () => _setWallet(Wallet.crypto)),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            title: 'شماره/کد تراکنش',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_lastTx, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('زمان: $_lastTime', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('کیف فعال: ${_walletName(_selectedWallet)}',
              textAlign: TextAlign.center, style: TextStyle(color: green, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ]),
      ),
    );
  }

  Widget _btn(BuildContext context, String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: const StadiumBorder()),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFCDE7D0),
    );
  }
}

// ================== BT PAGE ==================
class BtPayPage extends StatefulWidget {
  final int currentBalance;
  final Future<void> Function(int amount, String txid) onSuccess;
  const BtPayPage({super.key, required this.currentBalance, required this.onSuccess});

  @override
  State<BtPayPage> createState() => _BtPayPageState();
}

class _BtPayPageState extends State<BtPayPage> {
  bool _secure = false;
  int _amount = 0;
  String _status = 'آماده';
  final _controller = TextEditingController();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selected;

  Future<void> _scan() async {
    setState(() {
      _status = 'در حال جست‌وجو...';
      _devices = [];
      _selected = null;
      _secure = false;
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    final results = await FlutterBluePlus.onScanResults.first;
    await FlutterBluePlus.stopScan();
    setState(() {
      _devices = results.map((e) => e.device).toList();
      _status = _devices.isEmpty ? 'چیزی پیدا نشد' : 'گزینش دستگاه';
    });
  }

  Future<void> _connect(BluetoothDevice d) async {
    setState(() {
      _status = 'اتصال...';
    });
    try {
      await d.connect(timeout: const Duration(seconds: 5));
    } catch (_) {}
    setState(() {
      _selected = d;
      _secure = true; // شبیه‌سازی امن
      _status = 'اتصال ایمن برقرار شد';
    });
  }

  Future<void> _submit() async {
    if (!_secure) return;
    final v = int.tryParse(_controller.text.trim()) ?? 0;
    if (v <= 0 || v > widget.currentBalance) {
      setState(() => _status = 'مبلغ نامعتبر است');
      return;
    }
    final txid = const Uuid().v4().substring(0, 8);
    await widget.onSuccess(v, txid);
    if (mounted) {
      setState(() => _status = 'تراکنش موفق: BT-$txid');
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green.shade700;
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت با بلوتوث')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ElevatedButton(onPressed: _scan, child: const Text('شروع جست‌وجو')),
          const SizedBox(height: 8),
          if (_devices.isNotEmpty)
            DropdownButton<BluetoothDevice>(
              isExpanded: true,
              value: _selected,
              hint: const Text('انتخاب دستگاه فروشنده'),
              items: _devices
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.platformName.isEmpty ? d.remoteId.str : d.platformName)))
                  .toList(),
              onChanged: (d) => _connect(d!),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(_secure ? Icons.verified_user : Icons.lock_outline, color: _secure ? green : Colors.grey),
            const SizedBox(width: 8),
            Text(_secure ? 'اتصال ایمن' : 'در انتظار اتصال ایمن'),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'مبلغ خرید',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _submit, child: const Text('پرداخت')),
          ),
          const SizedBox(height: 12),
          Text('وضعیت: $_status'),
        ]),
      ),
    );
  }
}

// ================== QR PAGE ==================
class QrPayPage extends StatefulWidget {
  final String walletName;
  final int currentBalance;
  final Future<void> Function(int amount, String txid) onSuccess;
  const QrPayPage({super.key, required this.walletName, required this.currentBalance, required this.onSuccess});

  @override
  State<QrPayPage> createState() => _QrPayPageState();
}

class _QrPayPageState extends State<QrPayPage> {
  final _amountCtrl = TextEditingController();
  String? _payload; // مرحله اول: QR درخواست پرداخت
  bool _awaitingConfirm = false;
  String _status = 'انتخاب مبلغ و تولید/اسکن QR';

  String _makeRequestPayload(int amount) {
    final tx = {
      'type': 'PAY_REQ',
      'amount': amount,
      'wallet': widget.walletName,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'nonce': const Uuid().v4().substring(0, 6),
    };
    return jsonEncode(tx);
  }

  Future<void> _genRequest() async {
    final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt <= 0 || amt > widget.currentBalance) {
      setState(() => _status = 'مبلغ نامعتبر است');
      return;
    }
    setState(() {
      _payload = _makeRequestPayload(amt);
      _awaitingConfirm = true;
      _status = 'QR درخواست ساخته شد — منتظر تأیید فروشنده';
    });
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const _ScanView()));
    if (code == null) return;

    try {
      final data = jsonDecode(code);
      if (data['type'] == 'PAY_CONF') {
        final int amount = data['amount'] ?? 0;
        final String txid = data['txid'] ?? const Uuid().v4().substring(0, 8);
        await widget.onSuccess(amount, txid);
        if (mounted) {
          setState(() {
            _payload = null;
            _awaitingConfirm = false;
            _status = 'تراکنش موفق: QR-$txid';
          });
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.pop(context);
        }
      } else {
        setState(() => _status = 'QR نامعتبر است');
      }
    } catch (_) {
      setState(() => _status = 'QR قابل خواندن نیست');
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت با QR')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'مبلغ خرید', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _genRequest, child: const Text('تولید QR (درخواست)'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: _scan, child: const Text('اسکن QR'))),
            ],
          ),
          const SizedBox(height: 12),
          if (_payload != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text('درخواست پرداخت — ${widget.walletName}', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  QrImageView(data: _payload!, size: 220),
                  const SizedBox(height: 6),
                  const Text('این QR را فروشنده اسکن می‌کند'),
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
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final raw = barcodes.first.rawValue;
            if (raw != null) Navigator.pop(context, raw);
          }
        },
      ),
    );
  }
}
