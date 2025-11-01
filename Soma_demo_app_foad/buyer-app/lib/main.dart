import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/qr_screen.dart';
import 'screens/bluetooth_pay_screen.dart';
import 'services/local_db.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF27AE60);
    const Color bg = Color(0xFFF7FAFC);
    const Color dark = Color(0xFF0B2545);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما — خریدار',
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
        '/': (_) => const BuyerHomePage(),
        '/qr': (_) => const QrScreen(),
        '/pay/bluetooth': (_) => const BluetoothPayScreen(),
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
  final _fmt = NumberFormat.decimalPattern('fa');
  int _balance = 0;
  String _wallet = 'main';
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _balance = await LocalDB.instance.getBalance(wallet: _wallet);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int _parseAmount() {
    final t = (_amountCtrl.text).replaceAll(',', '').replaceAll('٬', '');
    return int.tryParse(t) ?? 0;
  }

  void _gotoBt() {
    Navigator.pushNamed(
      context,
      '/pay/bluetooth',
      arguments: {'amount': _parseAmount(), 'wallet': _wallet},
    );
  }

  void _gotoQr() {
    Navigator.pushNamed(
      context,
      '/qr',
      arguments: {'amount': _parseAmount(), 'wallet': _wallet},
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ آفلاین سوما')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await LocalDB.instance.addBalance(100000, wallet: _wallet);
            await _load();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('۱۰۰٬۰۰۰ ریال به موجودی کیف پول انتخابی اضافه شد.')),
            );
          },
          label: const Text('افزایش موجودی آزمایشی'),
          icon: const Icon(Icons.add_card),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('اپ خریدار', style: Theme.of(context).textTheme.titleLarge),
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

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مبلغ خرید'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'مثلاً ۵۰۰٬۰۰۰',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Text('نحوه پرداخت',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: green)),
            const SizedBox(height: 8),
            _actionBtn(Icons.bluetooth, 'پرداخت با بلوتوث', _gotoBt),
            const SizedBox(height: 8),
            _actionBtn(Icons.qr_code_2, 'پرداخت با QR کد', _gotoQr),

            const SizedBox(height: 16),

            Text('انتخاب کیف پول',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: green)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                _walletChip('موجودی حساب اصلی', 'main'),
                _walletChip('موجودی یارانه', 'subsidy'),
                _walletChip('موجودی اضطراری ملی', 'emergency'),
                _walletChip('موجودی کیف پول رمز ارز ملی', 'cbdc'),
              ],
            ),
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

  Widget _walletChip(String label, String key) => ChoiceChip(
        label: Text(label),
        selected: _wallet == key,
        onSelected: (v) async {
          setState(() => _wallet = key);
          await _load();
        },
      );
}
