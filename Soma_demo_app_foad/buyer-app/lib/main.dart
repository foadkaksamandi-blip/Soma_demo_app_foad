import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'screens/scan_qr_screen.dart';

void main() {
  // فرمت پیش‌فرض به فارسی/انگلیسی
  Intl.defaultLocale = 'fa';
  runApp(const BuyerApp());
}

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما – خریدار',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [
        Locale('fa'),
        Locale('en'),
      ],
      // ⚠️ این‌ها نباید const باشند
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF19B394)),
      ),
      initialRoute: '/scan/qr',
      routes: {
        '/scan/qr': (_) => const QrPayScreen(), // همون فایل فعلی تو مسیر screens/scan_qr_screen.dart
      },
    );
  }
}
