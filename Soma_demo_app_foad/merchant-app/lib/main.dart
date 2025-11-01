import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'services/local_db.dart';
import 'screens/bluetooth_receive_screen.dart';
import 'screens/generate_qr_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

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
        '/receive/bluetooth': (_) => const BluetoothReceiveScreen(),
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
  final _nf = NumberFormat.decimalPattern('fa');
  final TextEditingController amountCtrl = TextEditingController();
  String? lastTxnCode;
  String? lastTxnMethod;
  DateTime? lastTxnTime;

  int get _balance => LocalDBMerchant.instance.merchantBalance;

  void _refreshBalance() => setState(() {});
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
            Text('اپ فروشنده', style: Theme.of(context).textTheme.titleLarge),

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
                  OutlinedButton(onPressed: _refreshBalance, child: const Text('بروزرسانی')),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // مبلغ فروش
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.25)),
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
                      hintText: 'مثلاً ۵۰۰٬۰۰۰', border: OutlineInputBorder(), isDense: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // روش دریافت
            Text('دریافت از طریق', style: Theme.of(context).textTheme.titleLarge!.copyWith(color: primaryGreen)),
            const SizedBox(height: 8),
            _ActionCard(
              icon: Icons.bluetooth_searching, color: accentTurquoise, title: 'دریافت با بلوتوث',
              onTap: () async {
                final amount = int.tryParse(amountCtrl.text.replaceAll('٬', '').replaceAll(',', '')) ?? 0;
                if (amount <= 0) {
                  _toast('مبلغ فروش را وارد کنید');
                  return;
                }
                final result = await Navigator.push<String>(
                  context, MaterialPageRoute(builder: (_) => BluetoothReceiveScreen(amount: amount)),
                );
                if (result != null) {
                  _recordTxn(code: result, method: 'Bluetooth / دریافت');
                }
              },
            ),
            const SizedBox(height: 8),
            _ActionCard(
              icon: Icons.qr_code_2, color: primaryGreen, title: 'تولید QR برای اسکن خریدار',
              onTap: () async {
                final amount = int.tryParse(amountCtrl.text.replaceAll('٬', '').replaceAll(',', '')) ?? 0;
                if (amount <= 0) {
                  _toast('مبلغ فروش را وارد کنید');
                  return;
                }
                final result = await Navigator.push<String>(
                  context, MaterialPageRoute(builder: (_) => GenerateQrScreen(amount: amount)),
                );
                if (result != null) {
                  _recordTxn(code: result, method: 'QR / دریافت');
                }
              },
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
