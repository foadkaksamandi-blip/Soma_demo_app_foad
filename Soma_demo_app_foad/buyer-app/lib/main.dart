import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/scan_qr_screen.dart'; // همانی که داری (QrPayScreen)
import 'services/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما - خریدار',
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      // این لیست نباید const باشد
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: null,
      ),
      routes: {
        '/': (_) => const _Home(),
        // سازنده را بدون const صدا بزن تا خطای "Not a constant expression" رفع شود
        '/scan/qr': (_) => QrPayScreen(),
      },
      initialRoute: '/',
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key});

  @override
  Widget build(BuildContext context) {
    // نمونه ساده؛ UI فعلی خودت را اگر داری همین‌جا نگه‌دار
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کیف پول (موجودی)'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'موجودی: ${LocalDb.buyerBalance} ریال',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/scan/qr', arguments: {
                  'expectedAmount': 100000,
                  'source': 'یارانه',
                }),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('پرداخت با اسکن QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
