import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import 'receive_bluetooth_screen.dart';
import 'generate_qr_screen.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  final _amountCtrl = TextEditingController();
  final _nf = NumberFormat.decimalPattern('fa');
  final TransactionService _tx = TransactionService();

  String _fmt(double v) => _nf.format(v.round());

  Color get _primary => const Color(0xFF27AE60);
  Color get _turquoise => const Color(0xFF1ABC9C);
  Color get _textDark => const Color(0xFF0B2545);

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('اپ آفلاین سوما — فروشنده'),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _turquoise,
          foregroundColor: Colors.white,
          onPressed: () {
            _tx.merchantBalance += 100000;
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('۱۰۰٬۰۰۰ ریال به موجودی اضافه شد')),
            );
          },
          icon: const Icon(Icons.add_card),
          label: const Text('افزایش موجودی آزمایشی'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // موجودی
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, color: Color(0xFF27AE60)),
                    const SizedBox(width: 8),
                    Text(
                      'موجودی: ${_fmt(_tx.merchantBalance)} ریال',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _turquoise,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() {}),
                      child: const Text('بروزرسانی'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // مبلغ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _primary.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مبلغ دریافت'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'مثلاً ۲۵۰٬۰۰۰',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // نحوه دریافت
              Text('روش دریافت',
                  style: TextStyle(
                      color: _primary, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _actionCard(
                icon: Icons.bluetooth_searching,
                title: 'دریافت با بلوتوث',
                color: _turquoise,
                onTap: () {
                  final amount = double.tryParse(_amountCtrl.text.replaceAll('٬', '')) ?? 0;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReceiveBluetoothScreen(amount: amount, tx: _tx),
                  ));
                },
              ),
              const SizedBox(height: 8),
              _actionCard(
                icon: Icons.qr_code_2,
                title: 'تولید QR برای خریدار',
                color: _primary,
                onTap: () {
                  final amount = double.tryParse(_amountCtrl.text.replaceAll('٬', '')) ?? 0;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GenerateQrScreen(amount: amount, tx: _tx),
                  ));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color, foregroundColor: Colors.white, child: Icon(icon)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
