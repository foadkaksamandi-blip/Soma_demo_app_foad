import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({super.key});

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  final List<ScanResult> _results = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  String _receivedData = '';
  bool _isScanning = false;
  bool _connected = false;

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    _results.clear();
    final sub = FlutterBluePlus.onScanResults.listen((list) {
      setState(() {
        _results
          ..clear()
          ..addAll(list);
      });
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    await FlutterBluePlus.stopScan();
    await sub.cancel();
    setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 8));
      setState(() {
        _connectedDevice = device;
        _connected = true;
      });

      final services = await device.discoverServices();
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify) {
            _rxCharacteristic = c;
            await c.setNotifyValue(true);
            c.onValueReceived.listen((value) {
              setState(() => _receivedData = utf8.decode(value));
            });
            break;
          }
        }
        if (_rxCharacteristic != null) break;
      }

      if (_rxCharacteristic == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Characteristic مناسب برای دریافت پیدا نشد')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اتصال: $e')),
      );
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    setState(() {
      _connectedDevice = null;
      _connected = false;
      _receivedData = '';
    });
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryTurquoise = Color(0xFF1ABC9C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('دریافت بلوتوث'),
        backgroundColor: primaryTurquoise,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [IconButton(onPressed: _startScan, icon: const Icon(Icons.refresh))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isScanning ? null : (_connected ? _disconnect : _startScan),
              icon: Icon(_connected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
              label: Text(_connected ? 'قطع اتصال' : 'جستجو'),
            ),
            const SizedBox(height: 12),
            Text(
              _connectedDevice != null ? 'متصل به: ${_connectedDevice!.platformName}' : 'Not connected',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _connected
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _receivedData.isEmpty ? 'هنوز داده‌ای دریافت نشده...' : _receivedData,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                  : (_results.isEmpty
                      ? const Center(child: Text('لیست دستگاه‌ها خالی است'))
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final r = _results[i];
                            final d = r.device;
                            return ListTile(
                              title: Text(d.platformName.isEmpty ? '(ناشناس)' : d.platformName),
                              subtitle: Text(d.remoteId.str),
                              trailing: ElevatedButton(
                                onPressed: () => _connectToDevice(d),
                                child: const Text('اتصال'),
                              ),
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
