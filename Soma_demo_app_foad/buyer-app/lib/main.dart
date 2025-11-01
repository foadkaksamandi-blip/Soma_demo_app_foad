import 'dart:ui' show TextDirection; // برای TextDirection.rtl
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/bluetooth_receive_screen.dart';
import 'screens/generate_qr_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fa';
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Offline Soma — Merchant',
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const _Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اپ آفلاین سوما — اپ فروشنده')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ خرید'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text) ?? 0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BluetoothReceiveScreen(amount: amount),
                    ),
                  );
                },
                child: const Text('دریافت از بلوتوث'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text) ?? 0;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GenerateQrScreen(amount: amount),
                    ),
                  );
                },
                child: const Text('دریافت از QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
