import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/qr_service.dart';
import '../services/local_db.dart';
import 'package:uuid/uuid.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final TextEditingController amountCtrl = TextEditingController();
  String? qrPayload;
  final uuid = const Uuid();

  String _fmt(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _generate() {
    final raw = amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _toast('مبلغ را وارد کنید');
      return;
    }
    final amount = int.tryParse(raw) ?? 0;
    if (amount <= 0) {
      _toast('مبلغ معتبر نیست');
      return;
    }
    final txId = 'SOMA-${DateTime.now().toIso8601String().split('T').first}-${uuid.v4().substring(0,6)}';
    final payload = MerchantQrService().buildPayload(amount: amount, txId: txId);
    setState(() {
      qrPayload = payload;
    });
    // ثبت تراکنش موقت در لاگ فروشنده (منتظر انجام توسط خریدار)
    LocalDBMerchant.instance.addMerchantTx(
      txId: txId,
      amount: amount,
      method: 'QR',
      ts: DateTime.now().millisecondsSinceEpoch,
      status: 'PENDING',
    );
    _toast('QR تولید شد (واقعی - داده JSON)');
  }

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textDirection: TextDirection.rtl), backgroundColor: ok ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(title: const Text('تولید QR فروش', textDirection: TextDirection.rtl), backgroundColor: successGreen),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: successGreen.withOpacity(0.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('مبلغ فروش'),
            const SizedBox(height: 8),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'مثلاً ۵۰۰٬۰۰۰', border: OutlineInputBorder(), isDense: true)),
          ])),
          const SizedBox(height: 12),
          SizedBox(height: 48, child: ElevatedButton.icon(onPressed: _generate, icon: const Icon(Icons.qr_code), label: const Text('تولید QR'), style: ElevatedButton.styleFrom(backgroundColor: successGreen, foregroundColor: Colors.white))),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryTurquoise.withOpacity(0.25))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('داده QR (JSON)'),
            const SizedBox(height: 8),
            Text(qrPayload ?? 'هنوز تولید نشده'),
          ])),
        ]),
      ),
    );
  }
}
