import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/bluetooth_pay_screen.dart';
import 'screens/qr_pay_screen.dart'; // خیلی مهم: ایمپورت مستقیم صفحه QR
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
        '/pay/bluetooth': (_) => BluetoothPayScreen(), // بدون const
        '/pay/qr': (_) => QrPayScreen(),               // بدون const + ایمپورت بالا
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

  String _format(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _refreshBalance() {
    setState(() {
      balance = LocalDB.instance.buyerBalance;
    });
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), // دیگه TextDirection.rtl لازم نیست
        backgroundColor: success ? const Color(0xFF27AE60) : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
    const Color successGreen = Color(0xFF27AE60);
    const Color textDark = Color(0xFF0B2545);

    return Directionality( // یک‌بار برای کل صفحه
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
              Text('اپ خریدار', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              // موجودی
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryTurquoise.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: successGreen),
                    const SizedBox(width: 8),
                    Text('${_format(balance)} ریال',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        )),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _refreshBalance,
                      style: ElevatedButton.styleFrom(backgroundColor: primaryTurquoise),
                      child: const Text('بروزرسانی'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // مبلغ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryTurquoise.withOpacity(0.25)),
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
                        hintText: 'مثلاً ۵۰۰٬۰۰۰ ریال',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // نحوه پرداخت
              Text('نحوه پرداخت',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: primaryTurquoise)),
              const SizedBox(height: 8),
              _PaymentCard(
                icon: Icons.bluetooth,
                title: 'پرداخت با بلوتوث',
                color: primaryTurquoise,
                onTap: () => Navigator.pushNamed(context, '/pay/bluetooth'),
              ),
              const SizedBox(height: 8),
              _PaymentCard(
                icon: Icons.qr_code_2,
                title: 'پرداخت با QR کد',
                color: successGreen,
                onTap: () => Navigator.pushNamed(context, '/pay/qr'),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryTurquoise.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'برای تست واقعی بلوتوث، اجازه‌ها را بدهید و دستگاه‌ها را جفت کنید؛ QR واقعی تولید و اسکن می‌شود.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: successGreen,
          foregroundColor: Colors.white,
          onPressed: () {
            LocalDB.instance.addBuyerBalance(100000);
            _showSnack('۱۰۰٬۰۰۰ ریال به موجودی آزمایشی اضافه شد.', success: true);
            _refreshBalance();
          },
          label: const Text('افزایش موجودی آزمایشی'),
          icon: const Icon(Icons.add_card),
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
