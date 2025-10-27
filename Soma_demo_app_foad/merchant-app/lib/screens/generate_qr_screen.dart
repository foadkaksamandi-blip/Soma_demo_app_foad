import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routes: {
        '/': (_) => const _Home(),
        '/bt/receive': (_) => const BluetoothReceiveScreen(),
        '/qr/generate': (_) => const ScanReceiptScreen(),
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
        appBar: AppBar(
          title: const Text('اپ آفلاین سوما – فروشنده'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.bluetooth),
                label: const Text('دریافت پرداخت بلوتوثی'),
                onPressed: () {
                  Navigator.pushNamed(context, '/bt/receive',
                      arguments: {'amount': '50000'});
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('نمایش QR برای پرداخت'),
                onPressed: () {
                  Navigator.pushNamed(context, '/qr/generate');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
