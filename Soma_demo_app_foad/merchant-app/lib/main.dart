import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/generate_qr_screen.dart';
import 'screens/bluetooth_receive_screen.dart';

void main() {
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Merchant',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('fa', 'IR'),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/qr': (context) => const GenerateQrScreen(amount: 0),
        '/bt': (context) => const BluetoothReceiveScreen(amount: 0),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('فروشنده (مرچنت)')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('مبلغ تراکنش را وارد کنید:'),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'مثلاً 250000',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text) ?? 0;
                  Navigator.pushNamed(
                    context,
                    '/qr',
                    arguments: {'amount': amount},
                  );
                },
                child: const Text('تولید QR پرداخت'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text) ?? 0;
                  Navigator.pushNamed(
                    context,
                    '/bt',
                    arguments: {'amount': amount},
                  );
                },
                child: const Text('دریافت با بلوتوث'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
