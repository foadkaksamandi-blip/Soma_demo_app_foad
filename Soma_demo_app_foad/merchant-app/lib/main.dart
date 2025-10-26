import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/generate_qr_screen.dart';
import 'screens/bluetooth_receive_screen.dart';
import 'services/local_db.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
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
        secondary: primaryTurquoise,
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark),
        bodyMedium: TextStyle(fontSize: 16, color: textDark),
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
  final TextEditingController amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    balance = LocalDBMerchant.instance.merchantBalance;
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  String _format(int rials) => NumberFormat.decimalPattern('fa').format(rials);

  void _refreshBalance() {
    setState(() {
      balance = LocalDBMerchant.instance.merchantBalance;
    });
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: success ? const Color(0xFF27AE60) : Colors.grey[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTurquoise = Color(0xFF1ABC9C);
    const Color successGreen = Color(0xFF27AE60);
    const Color textDark = Color(0xFF0B2545);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: successGreen,
        foregroundColor: Colors.white,
        title: const Text('اپ آفلاین سوما', textDirection: TextDirection.rtl),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('اپ فروشنده', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: successGreen.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: successGreen),
                    const SizedBox(width: 8),
                    Text('موجودی: ${_format(balance)} ریال',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textDark,
                        )),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _refreshBalance,
                      style: ElevatedButton.styleFrom(backgroundColor: successGreen),
                      child: const Text('بروزرسانی'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('دریافت از طریق',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: successGreen)),
              const SizedBox(height: 8),
              _ActionCard(
                icon: Icons.bluetooth_searching,
                title: 'دریافت با بلوتوث',
                color: primaryTurquoise,
                onTap: () => Navigator.pushNamed(context, '/bt/receive'),
              ),
              const SizedBox(height: 8),
              _ActionCard(
                icon: Icons.qr_code_2,
                title: 'تولید QR برای اسکن خریدار',
                color: successGreen,
                onTap: () => Navigator.pushNamed(context, '/qr/generate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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
