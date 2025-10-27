import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/scan_receipt_screen.dart';
import 'screens/bluetooth_receive_screen.dart';
import 'screens/qr_generate_screen.dart';

void main() {
  runApp(const MerchantApp());
}

class MerchantApp extends StatelessWidget {
  const MerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOMA Offline Demo - Merchant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/scan': (_) => const ScanScreen(),
        '/scan/receipt': (_) => const ScanReceiptScreen(),
        '/bluetooth/receive': (_) => const BluetoothReceiveScreen(),
        '/qr/generate': (_) => QrGenerateScreen(), // ← const حذف شد
      },
    );
  }
}
