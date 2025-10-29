import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import 'bluetooth_pay_screen.dart';
import 'scan_qr_screen.dart';

enum PaySource { balance, subsidy, emergency, crypto }

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final _amountCtrl = TextEditingController();
  final _nf = NumberFormat.decimalPattern('fa');
  PaySource _source = PaySource.balance;

  // یک نمونه سرویس مشترک برای صفحه‌ها
  final TransactionService _tx = TransactionService();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => _nf.format(v.round());

  Color get _primary => const Color(0xFF1ABC9C);
  Color get _success => const Color(0xFF27AE60);
  Color get _textDark => const Color(0xFF0B2545);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('اپ آفلاین سوما — خریدار'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _success,
          foregroundColor: Colors.white,
          onPressed: () {
            _tx.buyerBalance += 100000;
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('۱۰۰٬۰۰۰ ریال به موجودی اضافه شد.')),
            );
          },
          icon: const Icon(Icons.add_card),
          label: const Text('افزایش موجودی آزمایشی'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // کارت موجودی
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
                    'موجودی: ${_fmt(_tx.buyerBalance)} ریال',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary, foregroundColor: Colors.white),
                    onPressed: () => setState(() {}),
                    child: const Text('بروزرسانی'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // مبلغ خرید
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
                  const Text('مبلغ خرید'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'مثلاً ۵۰۰٬۰۰۰',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // منبع پرداخت
            Text('انتخاب منبع پرداخت',
                style: TextStyle(
                    color: _primary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('موجودی حساب', PaySource.balance),
                _chip('یارانه', PaySource.subsidy),
                _chip('اضطراری', PaySource.emergency),
                _chip('رمز ارز ملی', PaySource.crypto),
              ],
            ),
            const SizedBox(height: 24),
            // مسیرهای پرداخت
            Text('نحوه پرداخت',
                style: TextStyle(
                    color: _primary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _actionCard(
              icon: Icons.bluetooth,
              title: 'پرداخت با بلوتوث',
              color: _primary,
              onTap: () {
                final amount = double.tryParse(_amountCtrl.text.replaceAll('٬', '')) ?? 0;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BluetoothPayScreen(
                    amount: amount,
                    source: _source.name,
                    tx: _tx,
                  ),
                ));
              },
            ),
            const SizedBox(height: 8),
            _actionCard(
              icon: Icons.qr_code_scanner,
              title: 'پرداخت با QR کد (اسکن)',
              color: _success,
              onTap: () {
                final amount = double.tryParse(_amountCtrl.text.replaceAll('٬', '')) ?? 0;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ScanQrScreen(
                    expectedAmount: amount,
                    source: _source.name,
                    tx: _tx,
                  ),
                ));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, PaySource value) {
    final selected = _source == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _source = value),
      selectedColor: _primary.withOpacity(0.15),
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
              CircleAvatar(
                  backgroundColor: color, foregroundColor: Colors.white, child: Icon(icon)),
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
