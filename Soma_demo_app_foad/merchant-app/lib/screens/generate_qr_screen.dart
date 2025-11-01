import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/local_db.dart';

class GenerateQrScreen extends StatefulWidget {
  final int amount;
  const GenerateQrScreen({super.key, required this.amount});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String _qrData = '';

  @override
  void initState() {
    super.initState();
    _buildQr();
  }

  void _buildQr() {
    final payload = jsonEncode({
      "type": "REQ",
      "amount": widget.amount,
      "wallet": "main",
      "time": DateTime.now().toIso8601String(),
    });
    setState(() => _qrData = payload);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تولید QR پرداخت')),
        body: Center(
          child: _qrData.isEmpty
              ? const CircularProgressIndicator()
              : QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 280.0,
                ),
        ),
      ),
    );
  }
}
