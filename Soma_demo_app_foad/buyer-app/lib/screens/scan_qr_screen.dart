import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';
import '../services/permissions.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');
  late int _amount;
  late String _wallet;

  bool _showScanner = true;
  String? _txId;
  String? _status;
  String? _confirmPayload; // برای تولید QR پاسخ

  @override
  void initState() {
    super.initState();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _amount = (args['amount'] ?? 0) as int;
    _wallet = (args['wallet'] ?? 'main') as String;
  }

  Future<void> _ensureCam() async {
    final ok = await AppPermissions.ensureBtAndCamera();
    if (!ok) {
      setState(() => _status = 'مجوز دوربین لازم است.');
    }
  }

  Future<void> _onScan(String raw) async {
    // raw باید از فروشنده باشد: {"type":"REQ","amount":...}
    try {
      final m = jsonDecode(raw) as Map;
      final want = (m['amount'] ?? 0) as int;
      if (want != _amount) {
        setState(() => _status = 'مبلغ تطابق ندارد.');
        return;
      }
      final ok = await LocalDB.instance.spend(_amount, wallet: _wallet);
      if (!ok) {
        setState(() => _status = 'موجودی کافی نیست.');
        return;
      }
      final tx = LocalDB.instance.newTxId();
      setState(() {
        _txId = tx;
        _status = 'تراکنش موفق';
        _confirmPayload = jsonEncode({
          "type":"CONFIRM",
          "txId": tx,
          "amount": _amount,
          "wallet": _wallet,
          "ts": DateTime.now().toIso8601String()
        });
        _showScanner = false;
      });
    } catch (_) {
      setState(() => _status = 'QR نامعتبر');
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پرداخت با QR')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(children: [
                const Text('مبلغ: ', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('${_fmt.format(_amount)} ریال')
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('کیف پول: ', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(_walletFa(_wallet))
              ]),
              const SizedBox(height: 12),

              if (_showScanner) ...[
                ElevatedButton.icon(
                  onPressed: _ensureCam,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('اجازه دوربین'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      onDetect: (barcode) {
                        final v = barcode.barcodes.isNotEmpty
                            ? barcode.barcodes.first.rawValue
                            : barcode.raw ?? '';
                        if (v != null && v.isNotEmpty) {
                          _onScan(v);
                        }
                      },
                    ),
                  ),
                ),
              ] else ...[
                const Text('QR تایید برای فروشنده (اسکن کند):'),
                const SizedBox(height: 8),
                if (_confirmPayload != null)
                  QrImageView(
                    data: _confirmPayload!,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                const SizedBox(height: 16),
                if (_txId != null)
                  _receiptBox(
                    txId: _txId!,
                    method: 'QR',
                    amount: _fmt.format(_amount),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('بازگشت به صفحه اصلی'),
                )
              ],

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
            ],
          ),
        ),
      ),
    );
  }

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
