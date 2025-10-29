import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/transaction_service.dart';
import 'bluetooth_pay_screen.dart';
import 'scan_qr_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final _amountCtrl = TextEditingController();
  final _nf = NumberFormat.decimalPattern('fa');

  final TransactionService _tx = TransactionService();

  // منبع پرداخت: balance | subsidy | emergency | crypto
  String _source = 'balance';

  Color get _turquoise => const Color(0xFF1ABC9C);
  Color get _green => const Color(0xFF27AE60);
  Color get _textDark => const Color(0xFF0B2545);

  String _fmt(double v) => _nf.format(v.round());

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _pickSource(String s) => setState(() => _source = s);

  double _readAmount() {
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(raw) ?? 0;
  }

  Widget _sourceChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          selected: _source == 'balance',
          label: const Text('موجودی حساب'),
          onSelected: (_) => _pickSource('balance'),
        ),
        ChoiceChip(
          selected: _source == 'subsidy',
          label: const Text('موجودی یارانه'),
          onSelected: (_) => _pickSource('subsidy'),
        ),
        ChoiceChip(
          selected: _source == 'emergency',
          label: const Text('موجودی اضطراری ملی'),
          onSelected: (_) => _pickSource('emergency'),
        ),
        ChoiceChip(
          selected: _source == 'crypto',
          label: const Text('موجودی کیف پول رمز ارز ملی'),
          onSelected: (_) => _pickSource('crypto'),
        ),
      ],
    );
  }

  Widget _receiptBox() {
    final r = _tx.getLastReceipt();
    if (r == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _turquoise.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _turquoise.withOpacity(0.2)),
        ),
        child: const Text('هنوز تراکنشی ثبت نشده است.'),
      );
    }
    final t = r.timestamp;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final dd = '${t.year}/${t.month.toString().padLeft(2, '0')}/${t.day.toString().padLeft(2, '0')}';
    final methodFa = r.method == 'bluetooth' ? 'بلوتوث' : 'QR';
    final sourceFa = {
      'balance': 'موجودی حساب',
      'subsidy': 'موجودی یارانه',
      'emergency': 'موجودی اضطراری ملی',
      'crypto': 'موجودی کیف پول رمز ارز ملی',
    }[r.source]!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _green.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('رسید آخرین تراکنش', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('کد: ${r.id.substring(0, 12)}'),
          Text('مبلغ: ${_fmt(r.amount)} ریال'),
          Text('روش: $methodFa'),
          Text('منبع: $sourceFa'),
          Text('زمان: $dd — $hh:$mm'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _turquoise,
          foregroundColor: Colors.white,
          title: const Text('اپ آفلاین سوما — خریدار'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // موجودی (عنوان دقیق)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _turquoise.withOpacity(0.25)),
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
                        backgroundColor: _turquoise, foregroundColor: Colors.white),
                      onPressed: () => setState(() {}),
                      child: const Text('بروزرسانی'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green, foregroundColor: Colors.white),
                      onPressed: () {
                        _tx.addBuyerTestFunds(100000);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('۱۰۰٬۰۰۰ ریال به موجودی اضافه شد')),
                        );
                      },
                      icon: const Icon(Icons.add_card),
                      label: const Text('افزایش آزمایشی'),
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _turquoise.withOpacity(0.25)),
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

              // انتخاب منبع پرداخت (دکمه‌ها با عبارات قفل‌شده)
              Text('منبع پرداخت', style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: _turquoise, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _sourceChips(),
              const SizedBox(height: 16),

              // روش پرداخت
              Text('نحوه پرداخت', style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: _turquoise, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _payCard(
                icon: Icons.bluetooth,
                title: 'پرداخت با بلوتوث',
                color: _turquoise,
                onTap: () {
                  final amount = _readAmount();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BluetoothPayScreen(
                      amount: amount,
                      source: _source,
                      tx: _tx,
                    ),
                  )).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 8),
              _payCard(
                icon: Icons.qr_code_2,
                title: 'پرداخت با QR کد (اسکن)',
                color: _green,
                onTap: () {
                  final amount = _readAmount();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ScanQrScreen(
                      expectedAmount: amount,
                      source: _source,
                      tx: _tx,
                    ),
                  )).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 16),

              // رسید
              _receiptBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payCard({
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
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
