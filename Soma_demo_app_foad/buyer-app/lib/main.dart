import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/bluetooth_pay_screen.dart';
import 'screens/qr_pay_screen.dart';
import 'services/local_db.dart';
import 'services/transaction_service.dart';
import 'models/tx_log.dart';

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
        '/pay/bluetooth': (_) => const BluetoothPayScreen(),
        '/pay/qr': (_) => const QrPayScreen(),
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
  String selectedWallet = 'عادی';
  final _nf = NumberFormat.decimalPattern('fa');

  @override
  void initState() {
    super.initState();
    balance = LocalDB.instance.buyerBalance;
  }

  void _refreshBalance() {
    setState(() => balance = LocalDB.instance.buyerBalance);
  }

  String _format(int rials) => _nf.format(rials);

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
    const Color successGreen = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryTurquoise,
          foregroundColor: Colors.white,
          title: const Text('اپ آفلاین سوما — خریدار'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryTurquoise.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: successGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'موجودی: ${_format(balance)} ریال',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _refreshBalance,
                    style: ElevatedButton.styleFrom(backgroundColor: successGreen),
                    child: const Text('بروزرسانی'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => selectedWallet = 'یارانه'),
                  icon: const Icon(Icons.wallet),
                  label: const Text('یارانه'),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => selectedWallet = 'اضطراری'),
                  icon: const Icon(Icons.safety_check),
                  label: const Text('اضطراری'),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => selectedWallet = 'رمز ارز ملی'),
                  icon: const Icon(Icons.currency_bitcoin),
                  label: const Text('رمز ارز ملی'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'مبلغ خرید (ریال)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/pay/bluetooth'),
              icon: const Icon(Icons.bluetooth),
              label: const Text('پرداخت با بلوتوث'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryTurquoise),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/pay/qr'),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('پرداخت با QR کد'),
              style: ElevatedButton.styleFrom(backgroundColor: successGreen),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'کیف پول فعال: $selectedWallet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: successGreen,
          onPressed: () {
            LocalDB.instance.addBuyerBalance(100000);
            _refreshBalance();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('۱۰۰٬۰۰۰ ریال به موجودی افزوده شد.')),
            );
          },
          label: const Text('افزایش موجودی آزمایشی'),
          icon: const Icon(Icons.add_card),
        ),
      ),
    );
  }
}
