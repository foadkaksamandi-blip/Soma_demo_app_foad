import 'package:flutter/material.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  bool isBluetoothEnabled = false;
  bool isScanning = false;
  String status = 'برای دریافت پرداخت بلوتوث، اسکن را شروع کنید.';

  Future<void> _toggleBluetooth() async {
    // TODO: در نسخه‌ی بعدی به بلوتوث واقعی وصل می‌شود.
    setState(() {
      isBluetoothEnabled = !isBluetoothEnabled;
      status = isBluetoothEnabled ? 'بلوتوث فعال شد.' : 'بلوتوث غیرفعال شد.';
    });
  }

  Future<void> _startScan() async {
    setState(() {
      isScanning = true;
      status = 'درحال جستجو برای دستگاه فروشنده...';
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isScanning = false;
      status = 'دستگاه پیدا شد؛ پرداخت آزمایشی دریافت شد.';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('پرداخت آزمایشی با موفقیت دریافت شد.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('دریافت بلوتوث'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                value: isBluetoothEnabled,
                onChanged: (_) => _toggleBluetooth(),
                title: const Text('فعال‌سازی بلوتوث'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: isBluetoothEnabled && !isScanning ? _startScan : null,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(isScanning ? 'درحال اسکن...' : 'شروع اسکن'),
              ),
              const SizedBox(height: 24),
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const Spacer(),
              const Text(
                'نسخه دمو — پیاده‌سازی بلوتوث واقعی بعد از اتصال دو دستگاه تکمیل می‌شود.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
