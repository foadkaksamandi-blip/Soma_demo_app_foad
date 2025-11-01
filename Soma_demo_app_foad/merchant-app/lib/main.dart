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
    const Color green = Color(0xFF27AE60);
    const Color bg = Color(0xFFF7FAFC);
    const Color dark = Color(0xFF0B2545);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما — فروشنده',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
        appBarTheme: const AppBarTheme(backgroundColor: green, foregroundColor: Colors.white),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: dark),
          bodyMedium: TextStyle(fontSize: 16, color: dark),
        ),
      ),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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
  final _fmt = NumberFormat.decimalPattern('fa');
  int _balance = 0;

  Future<void> _load() async {
    _balance = await LocalDBMerchant.instance.balance;
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ آفلاین سوما')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('اپ فروشنده', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: green,
                    child: Icon(Icons.account_balance_wallet, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('موجودی: ${_fmt.format(_balance)} ریال',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  TextButton(onPressed: _load, child: const Text('بروزرسانی'))
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('دریافت از طریق',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: green)),
            const SizedBox(height: 8),
            _actionBtn(Icons.bluetooth_searching, 'دریافت با بلوتوث', () {
              Navigator.pushNamed(context, '/bt/receive');
            }),
            const SizedBox(height: 8),
            _actionBtn(Icons.qr_code_2, 'تولید QR برای اسکن خریدار', () {
              Navigator.pushNamed(context, '/qr/generate');
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData i, String t, VoidCallback onTap) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF27AE60).withOpacity(0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  child: Icon(i),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_left),
              ],
            ),
          ),
        ),
      );
}
