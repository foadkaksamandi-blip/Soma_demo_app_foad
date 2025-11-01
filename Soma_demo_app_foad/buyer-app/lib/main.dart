import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const BuyerApp());

class BuyerApp extends StatelessWidget {
  const BuyerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soma Buyer',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const BuyerHomePage(),
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});
  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  final String buyerId = const Uuid().v4();
  String? lastScanned;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("App Offline Soma — Buyer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("My ID (for demo): $buyerId"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const _ScanPage(title: "Scan Merchant QR"),
                )).then((value) {
                  if (value is String) setState(() => lastScanned = value);
                });
              },
              child: const Text("Scan QR"),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("My QR (share to merchant)"),
                    const SizedBox(height: 12),
                    Center(
                      child: QrImageView(
                        data: '{"type":"buyer","id":"$buyerId"}',
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (lastScanned != null) ...[
              const SizedBox(height: 16),
              const Text("Last scanned payload:"),
              SelectableText(lastScanned!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanPage extends StatelessWidget {
  final String title;
  const _ScanPage({required this.title});
  @override
  Widget build(BuildContext context) {
    final controller = MobileScannerController();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcode = capture.barcodes.firstOrNull;
          final value = barcode?.rawValue;
          if (value != null) {
            Navigator.of(context).pop(value);
          }
        },
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : this[0];
}
