import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/transaction_service.dart';

class GenerateQrScreen extends StatefulWidget {
  final double amount;
  final String source;
  final TransactionService tx;

  const GenerateQrScreen({
    super.key,
    required this.amount,
    required this.source,
    required this.tx,
  });

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  late final String _qrData;
  Color get _primary => const Color(0xFF1ABC9C);

  @override
  void initState() {
    super.initState();
    _qrData = widget.tx.createQrData(widget.amount);
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.amount.toInt().toString();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('دریافت با QR'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(data: _qrData, size: 220),
              const SizedBox(height: 20),
              Text('مبلغ: $amountText ریال',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text(
                'خریدار می‌تواند این QR را اسکن کرده و پرداخت کند.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
