import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SomaMerchantApp());
}

const _green = Color(0xFF1E8449);

class SomaMerchantApp extends StatelessWidget {
  const SomaMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اپ آفلاین سوما — فروشنده',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _green),
        scaffoldBackgroundColor: const Color(0xFFF5F9F6),
        useMaterial3: true,
      ),
      home: const MerchantHomePage(),
    );
  }
}
