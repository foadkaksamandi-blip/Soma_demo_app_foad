import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// صفحه تولید QR
import 'screens/generate_qr_screen.dart';

void main() {
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
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
  int balance = 0; // موجودی نمایشی
  final TextEditingController amountCtrl = TextEditingController();

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  String _format(int rials) => NumberFormat.decimalPattern('fa').format(rials);

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

              // موجودی
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
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // مبلغ فروش
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: successGreen.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مبلغ فروش'),
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
                onTap: () => _showSnack('اتصال بلوتوث در Batch بعدی فعال می‌شود.'),
              ),
              const SizedBox(height: 8),

              _ActionCard(
                icon: Icons.qr_code_2,
                title: 'دریافت با QR کد (تولید QR)',
                color: successGreen,
                onTap: () => Navigator.pushNamed(context, '/qr/generate'),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'نسخه نمایشی — بدون اتصال بانکی • قابلیت‌های بلوتوث و QR در مراحل بعدی اضافه می‌شوند.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        onPressed: () {
          setState(() => balance += 150000);
          _showSnack('۱۵۰٬۰۰۰ ریال به موجودی نمایشی فروشنده اضافه شد.', success: true);
        },
        label: const Text('افزایش موجودی آزمایشی'),
        icon: const Icon(Icons.add),
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
