import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/material.dart';

class QrService {
  static String generateTransactionQR(Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    return encoded;
  }

  static Future<void> scanQR(
      BuildContext context, void Function(Map<String, dynamic>) onResult) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRViewExample(onResult: onResult),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  final void Function(Map<String, dynamic>) onResult;
  const QRViewExample({required this.onResult, super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: QRView(
        key: qrKey,
        onQRViewCreated: (ctrl) {
          controller = ctrl;
          controller!.scannedDataStream.listen((scanData) {
            final decoded = jsonDecode(scanData.code ?? '{}');
            widget.onResult(decoded);
            Navigator.pop(context);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
