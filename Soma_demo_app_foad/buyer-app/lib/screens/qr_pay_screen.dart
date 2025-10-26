import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/qr_service.dart';
import '../services/local_db.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

class QrPayScreen extends StatefulWidget {
  const QrPayScreen({super.key});

  @override
  State<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends State<QrPayScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  String? scannedRaw;
  final uuid = const Uuid();

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _startScan() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerPage(onDetect: (raw) {
          setState(() {
            scannedRaw = raw;
          });
          Navigator.pop(context);
          _toast('QR اسکن شد');
        })));
  }

  void _confirmPayment() {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _toast('مبلغ را وارد کنید');
      return;
    }
    if (scannedRaw == null) {
      _toast('ابتدا QR را اسکن کنید');
      return;
    }
    final parsed = BuyerQrService().parse(scannedRaw!);
    if (parsed == null) {
      _toast('QR نامعتبر است');
      return;
    }
    final amount = int.tryParse(raw) ?? 0;
    if (amount != parsed['amount']) {
      _toast('مبلغ واردشده با مقدار QR مطابقت ندارد');
      return;
    }
    final txId = parsed['tx_id'] ?? 'SOMA-${DateTime.now().millisecondsSinceEpoch.toString()}';
    // کاهش موجودی و ثبت تراکنش
    LocalDB.instance.addBuyerBalance(-amount);
    LocalDB.instance.addBuyerTx(
      txId: txId,
      amount: amount,
      method: 'QR',
      ts: DateTime.now().millisecondsSinceEpoch,
      status: 'SUCCESS',
    );
    _showSuccess(amount, txId);
  }

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl), backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  void _showSuccess(int amount, String txId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('پرداخت موفق', textDirection: TextDirection.rtl),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('مبلغ: ${_fmt(amount)} ریال'),
            const SizedBox(height: 8),
            Text('کد تراکنش: $txId'),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('باشه'))],
      ),
    );
    _toast('پرداخت با موفقیت انجام شد', ok: true);
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        title: const Text('پرداخت با QR کد', textDirection: TextDirection.rtl),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTurquoise.withOpacity(0.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('مبلغ پرداختی'),
            const SizedBox(height: 8),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'مثلاً ۵۰۰٬۰۰۰', border: OutlineInputBorder(), isDense: true)),
          ])),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTurquoise.withOpacity(0.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('اسکن QR فروشنده'),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: _startScan, icon: const Icon(Icons.qr_code_2), label: const Text('اسکن QR'), style: ElevatedButton.styleFrom(backgroundColor: primaryTurquoise, foregroundColor: Colors.white)),
            const SizedBox(height: 8),
            Text(scannedRaw == null ? 'هنوز چیزی اسکن نشده' : 'داده: $scannedRaw'),
          ])),
          const SizedBox(height: 16),
          SizedBox(height: 48, child: ElevatedButton.icon(onPressed: _confirmPayment, icon: const Icon(Icons.check), label: const Text('تأیید و پرداخت'), style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white))),
        ]),
      ),
    );
  }
}

class ScannerPage extends StatelessWidget {
  final void Function(String) onDetect;
  const ScannerPage({required this.onDetect, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اسکن QR', textDirection: TextDirection.rtl)),
      body: MobileScanner(
        allowDuplicates: false,
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue ?? '';
          onDetect(code);
        },
      ),
    );
  }
}
