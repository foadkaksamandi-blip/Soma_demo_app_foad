import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'services/local_db.dart';
import 'screens/bluetooth_pay_screen.dart';
import 'screens/qr_scan_screen.dart'; // توجه: اگر نام فایل شما متفاوت است، همین را با نام موجودتان هماهنگ کنید.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF27AE60);
    const Color accentTurquoise = Color(0xFF1ABC9C);
    const Color textDark = Color(0xFF0B2545);
    const Color bgLight = Color(0xFFF7FAFC);

    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentTurquoise,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        bodyMedium: TextStyle(fontSize: 16, color: textDark),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما — خریدار',
      theme: theme,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routes: {
        '/': (_) => const BuyerHomePage(),
        '/pay/bluetooth': (_) => const BluetoothPayScreen(),
        '/scan/qr': (_) => const QrScanScreen(),
      },
      initialRoute: '/',
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final _nf = NumberFormat.decimalPattern('fa');
  final TextEditingController amountCtrl = TextEditingController();
  String? lastTxnCode;
  String? lastTxnMethod; // Bluetooth / QR + نوع کیف
  DateTime? lastTxnTime;

  int get _balance => LocalDB.instance.buyerBalance;

  void _refreshBalance() => setState(() {});

  void _addTestFunds() {
    LocalDB.instance.addBuyerBalance(100000);
    _toast('۱۰۰٬۰۰۰ ریال به موجودی اضافه شد', success: true);
    _refreshBalance();
  }

  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(textDirection: TextDirection.rtl, child: Text(msg)),
        backgroundColor: success ? const Color(0xFF27AE60) : Colors.black87,
      ),
    );
  }

  void _recordTxn({required String code, required String method}) {
    setState(() {
      lastTxnCode = code;
      lastTxnMethod = method;
      lastTxnTime = DateTime.now();
    });
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF27AE60);
    const Color accentTurquoise = Color(0xFF1ABC9C);
    const Color textDark = Color(0xFF0B2545);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          title: const Text('اپ آفلاین سوما'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('اپ خریدار', style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 16),

            // موجودی + کنترل‌ها
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: primaryGreen),
                  const SizedBox(width: 8),
                  Text('موجودی: ${_nf.format(_balance)} ریال',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
                  const Spacer(),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(onPressed: _refreshBalance, child: const Text('بروزرسانی')),
                      FilledButton(onPressed: _addTestFunds, child: const Text('افزایش موجودی آزمایشی')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // مبلغ خرید کاربر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مبلغ خرید'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'مثلاً ۵۰۰٬۰۰۰', border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // روش پرداخت
            Text('نحوه پرداخت', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: primaryGreen)),
            const SizedBox(height: 8),
            _PaymentCard(
              icon: Icons.bluetooth, color: accentTurquoise, title: 'پرداخت با بلوتوث',
              onTap: () async {
                final amount = int.tryParse(amountCtrl.text.replaceAll('٬', '').replaceAll(',', '')) ?? 0;
                if (amount <= 0) {
                  _toast('مبلغ خرید را وارد کنید');
                  return;
                }
                final result = await Navigator.push<String>(
                  context, MaterialPageRoute(builder: (_) => BluetoothPayScreen(amount: amount)),
                );
                if (result != null) {
                  _recordTxn(code: result, method: 'Bluetooth / موجودی اصلی');
                }
              },
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              icon: Icons.qr_code_2, color: primaryGreen, title: 'پرداخت با QR کد',
              onTap: () async {
                final amount = int.tryParse(amountCtrl.text.replaceAll('٬', '').replaceAll(',', '')) ?? 0;
                if (amount <= 0) {
                  _toast('مبلغ خرید را وارد کنید');
                  return;
                }
                final result = await Navigator.push<String>(
                  context, MaterialPageRoute(builder: (_) => QrScanScreen(amount: amount)),
                );
                if (result != null) {
                  _recordTxn(code: result, method: 'QR / موجودی اصلی');
                }
              },
            ),

            const SizedBox(height: 16),

            // کیف‌های جایگزین (نمای واقعی با همان فلو اصلی)
            Text('کیف‌های پرداخت (انتخاب مبدأ)', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: primaryGreen)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TagButton(label: 'موجودی یارانه', onTap: () {
                  _toast('روش پرداخت: موجودی یارانه (از صفحه بلوتوث/QR انتخاب شود)');
                }),
                _TagButton(label: 'موجودی اضطراری ملی', onTap: () {
                  _toast('روش پرداخت: موجودی اضطراری ملی (از صفحه بلوتوث/QR انتخاب شود)');
                }),
                _TagButton(label: 'موجودی کیف پول رمز ارز ملی', onTap: () {
                  _toast('روش پرداخت: کیف پول رمز ارز ملی (از صفحه بلوتوث/QR انتخاب شود)');
                }),
              ],
            ),

            const SizedBox(height: 20),

            // لاگ تراکنش
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ثبت تراکنش اخیر'),
                  const SizedBox(height: 8),
                  Text('کد تراکنش: ${lastTxnCode ?? '-'}'),
                  Text('روش: ${lastTxnMethod ?? '-'}'),
                  Text('زمان: ${lastTxnTime != null ? DateFormat('yyyy/MM/dd HH:mm:ss', 'fa').format(lastTxnTime!) : '-'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
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
              Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TagButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
