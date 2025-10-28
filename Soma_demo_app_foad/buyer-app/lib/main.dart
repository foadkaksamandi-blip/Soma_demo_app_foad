import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// صفحات
import 'screens/bluetooth_pay_screen.dart';
import 'screens/scan_qr_screen.dart';

// سرویس‌های داخلی
import 'services/local_db.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Colors.teal;
    const success = Colors.green;
    const textDark = Colors.black87;

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      brightness: Brightness.light,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        bodyMedium: TextStyle(fontSize: 16, color: textDark),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما - خریدار',
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
        '/scan/qr': (_) => const QrPayScreen(), // 🔹 مسیر جدید و منظم‌تر
      },
      initialRoute: '/',
      theme: theme,
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
  final NumberFormat _nf = NumberFormat.decimalPattern('fa');

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

  String _format(int rials) => _nf.format(rials);

  void _refreshBalance() {
    setState(() => balance = LocalDB.instance.buyerBalance);
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Colors.teal;
    const success = Colors.green;
    const textDark = Colors.black87;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('اپ آفلاین سوما'),
        centerTitle: true,
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: success),
                  const SizedBox(width: 8),
                  Text(
                    'موجودی: ${_format(balance)} ریال',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _refreshBalance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
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
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مبلغ خرید', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'مثلاً ۱۰۰۰۰ ریال',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // نحوه پرداخت
            const Text('نحوه پرداخت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            _PaymentCard(
              icon: Icons.bluetooth,
              title: 'پرداخت با بلوتوث',
              color: primary,
              onTap: () => Navigator.pushNamed(context, '/pay/bluetooth'),
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              icon: Icons.qr_code_2,
              title: 'پرداخت با اسکن QR',
              color: success,
              onTap: () => Navigator.pushNamed(context, '/scan/qr'),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'برای تست واقعی بلوتوث و QR، اجازه‌ها را بدهید و دستگاه‌ها را جفت کنید.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: success,
        foregroundColor: Colors.white,
        onPressed: () {
          LocalDB.instance.addBuyerBalance(100000);
          _showSnack('۱۰۰,۰۰۰ ریال به موجودی آزمایشی اضافه شد.', success: true);
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
              CircleAvatar(
                backgroundColor: color,
                foregroundColor: Colors.white,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
