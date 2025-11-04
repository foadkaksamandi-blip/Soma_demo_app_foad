import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String? generatedData;

  void _generate() {
    setState(() {
      generatedData = 'TXN-${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تولید QR برای پرداخت')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _generate,
              child: const Text('تولید QR جدید'),
            ),
            const SizedBox(height: 16),
            if (generatedData != null)
              QrImage(
                data: generatedData!,
                version: QrVersions.auto,
                size: 200,
              ),
          ],
        ),
      ),
    );
  }
}
