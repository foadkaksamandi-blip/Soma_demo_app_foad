import 'dart:ui' show TextDirection;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveQrScreen extends StatefulWidget {
  const ReceiveQrScreen({super.key});

  @override
  State<ReceiveQrScreen> createState() => _ReceiveQrScreenState();
}

class _ReceiveQrScreenState extends State<ReceiveQrScreen> {
  final _fmt = NumberFormat.decimalPattern('fa');

  int _amount = 0;
  String _status = 'هنوز تولید نشده';
  String? _payload; // محتوای QR برای نمایش به خریدار

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
      _amount = (args['amount'] ?? 0) as int;
      setState(() {});
    });
  }

  void _generate() {
    // payload ساده دمو
    _payload = '{"type":"REQ","amount":$_amount}';
    setState(() {
      _status = 'برای نمایش به خریدار تولید شد';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('دریافت با QR')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مبلغ دریافتی از خریدار: ${_fmt.format(_amount)} تومان'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _generate,
                child: const Text('QR تولید برای نمایش به خریدار'),
              ),
              const SizedBox(height: 8),
              Text(_status),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: _payload == null
                      ? const SizedBox.shrink()
                      : QrImageView(
                          data: _payload!,
                          version: QrVersions.auto,
                          size: 240,
                        ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ثبت دریافت و بازگشت'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
