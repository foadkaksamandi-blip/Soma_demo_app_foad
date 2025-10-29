import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SomaBuyerApp());
}

class SomaBuyerApp extends StatelessWidget {
  const SomaBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Offline Buyer App',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const BuyerHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
