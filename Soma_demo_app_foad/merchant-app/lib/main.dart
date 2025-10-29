import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SomaMerchantApp());
}

class SomaMerchantApp extends StatelessWidget {
  const SomaMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Offline Merchant App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const MerchantHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
