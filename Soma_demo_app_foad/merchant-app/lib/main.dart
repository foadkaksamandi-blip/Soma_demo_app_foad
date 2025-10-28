import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/bluetooth_receive_screen.dart';
import 'screens/generate_qr_screen.dart';
import 'services/local_db.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color successGreen = Color(0xFF27AE60);
    const Color textDark = Color(0xFF0B2545);
    const Color bgLight = Color(0xFFF7FAFC);

    final theme = ThemeData(
      useMaterial3: true,
      primaryColor: successGreen,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: successGreen,
        primary: successGreen,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما — فروشنده',
      theme: theme,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routes: {
        '/': (_) => const MerchantHomePage(),
        '/qr/generate': (_) => const GenerateQrScreen(),
        '/bt/receive': (_) => const BluetoothReceiveScreen(),
      },
      initialRoute: '/',
    );
  }
}

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  int balance = LocalDBMerchant.instance.merchantBalance;
  final _nf = NumberFormat.decimalPattern('fa');

  void _refreshBalance() {
    setState(() => balance = LocalDBMerchant.instance.merchantBalance);
  }

  String _format(int rials) => _nf.format(rials);

  @override
  Widget build(BuildContext context) {
    const successGreen = Color(0xFF27AE60);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        title: const Text('اپ آفلاین سوما — فروشنده'),
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
              border: Border.all(color: successGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: successGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'موجودی: ${_format(balance)} ریال',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/bt/receive'),
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('دریافت با بلوتوث'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/qr/generate'),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('دریافت با QR کد'),
            style: ElevatedButton.styleFrom(backgroundColor: successGreen),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'کد تراکنش و زمان هر پرداخت در لاگ ذخیره می‌شود.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
