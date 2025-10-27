import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/bluetooth_pay_screen.dart';
import 'screens/scan_qr_screen.dart';
import 'services/local_db.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
    const Color successGreen = Color(0xFF27AE60);
    const Color textDark = Color(0xFF0B2545);
    const Color bgLight = Color(0xFFF7FAFC);

    final theme = ThemeData(
      useMaterial3: true,
      primaryColor: primaryTurquoise,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTurquoise,
        primary: primaryTurquoise,
        secondary: successGreen,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        bodyMedium: TextStyle(fontSize: 16, color: textDark),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ خریدار سوما',
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
        '/pay/qr': (_) => const ScanQrScreen(),
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
  int balance = LocalDB.instance.buyerBalance;
  final TextEditingController amountCtrl = TextEditingController();
  final _nf = NumberFormat.decimalPattern('fa');

  // منبع پرداخت انتخابی
  String _source = 'یارانه'; // 'یارانه' | 'اضطراری' | 'رمز ارز ملی'

  @override
  void initState() {
    super.initState();
    balance = LocalDB.instance.buyerBalance;
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  String _fmt(int rials) => _nf.format(rials);

  void _refreshBalance() => setState(() => balance = LocalDB.instance.buyerBalance);

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: success ? const Color(0xFF27AE60) : Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        title: const Text('اپ آفلاین سوما'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('کیف پول', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),

            // کارت موجودی
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryTurquoise.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Color(0xFF27AE60)),
                  const SizedBox(width: 8),
                  Text('${_fmt(balance)} ریال', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _refreshBalance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryTurquoise,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('بروزرسانی'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // انتخاب منبع پرداخت
            Text('منبع پرداخت', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: primaryTurquoise)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('یارانه'),
                  selected: _source == 'یارانه',
                  onSelected: (_) => setState(() => _source = 'یارانه'),
                ),
                ChoiceChip(
                  label: const Text('اضطراری'),
                  selected: _source == 'اضطراری',
                  onSelected: (_) => setState(() => _source = 'اضطراری'),
                ),
                ChoiceChip(
                  label: const Text('رمز ارز ملی'),
                  selected: _source == 'رمز ارز ملی',
                  onSelected: (_) => setState(() => _source = 'رمز ارز ملی'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // مبلغ خرید
            Text('مبلغ خرید', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: primaryTurquoise)),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'مثلاً ۵۰۰٬۰۰۰ ریال',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: 16),

            // روش پرداخت
            Text('نحوه پرداخت', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: primaryTurquoise)),
            const SizedBox(height: 8),

            _PaymentCard(
              icon: Icons.bluetooth,
              color: primaryTurquoise,
              title: 'پرداخت با بلوتوث',
              onTap: () {
                final amt = int.tryParse(amountCtrl.text.replaceAll(',', '').replaceAll('٬', '')) ?? 0;
                Navigator.pushNamed(
                  context,
                  '/pay/bluetooth',
                  arguments: {'amount': amt, 'source': _source},
                );
              },
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              icon: Icons.qr_code_scanner,
              color: const Color(0xFF27AE60),
              title: 'پرداخت با اسکن QR',
              onTap: () {
                final amt = int.tryParse(amountCtrl.text.replaceAll(',', '').replaceAll('٬', '')) ?? 0;
                Navigator.pushNamed(
                  context,
                  '/pay/qr',
                  arguments: {'expectedAmount': amt, 'source': _source},
                );
              },
            ),

            const SizedBox(height: 24),

            // توضیح
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryTurquoise.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'واقعی: تولید و اسکنِ کد QR برای تست واقعی بلوتوث با جفت‌کردن دستگاه‌ها و دادن مجوزها. '
                'اسکن دوربین در این نسخه فعال است.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),

      // افزایش موجودی آزمایشی
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF27AE60),
        foregroundColor: Colors.white,
        onPressed: () {
          LocalDB.instance.addBuyerBalance(100000);
          _showSnack('۱۰۰٬۰۰۰ ریال به موجودی آزمایشی اضافه شد.', success: true);
          _refreshBalance();
        },
        label: const Text('افزایش موجودی آزمایشی'),
        icon: const Icon(Icons.add_card),
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
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
