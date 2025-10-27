import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/bluetooth_receive_screen.dart';
import 'screens/generate_screen.dart'; // همون فایل generate شما

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'اپ آفلاین سوما — پذیرنده',
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      // دقت کن: این Map «const» نیست تا خطای Not a constant expression نگیریم.
      routes: {
        '/': (_) => const _Home(),
        '/bt/receive': (_) => const BluetoothReceiveScreen(),
        '/qr/generate': (_) => const QrGenerateScreen(),
      },
      initialRoute: '/',
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پذیرنده — دمو')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text('دریافت پرداخت با بلوتوث'),
              onPressed: () {
                Navigator.pushNamed(context, '/bt/receive',
                    arguments: {'amount': '۵۰۰٬۰۰۰ ریال'});
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_2),
              label: const Text('تولید QR پرداخت'),
              onPressed: () => Navigator.pushNamed(context, '/qr/generate'),
            ),
          ],
        ),
      ),
    );
  }
}
