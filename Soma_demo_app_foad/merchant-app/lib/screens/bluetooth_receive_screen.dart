import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class BluetoothReceiveScreen extends StatefulWidget {
  const BluetoothReceiveScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothReceiveScreen> createState() => _BluetoothReceiveScreenState();
}

class _BluetoothReceiveScreenState extends State<BluetoothReceiveScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  String _receivedData = '';
  bool _isScanning = false;
  bool _connected = false;

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.name.isNotEmpty && !_connected) {
          await FlutterBluePlus.stopScan();
          await _connectToDevice(r.device);
          break;
        }
      }
    });

    setState(() => _isScanning = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
    } catch (_) {}
    setState(() {
      _connectedDevice = device;
      _connected = true;
    });

    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.properties.notify) {
          _rxCharacteristic = c;
          await c.setNotifyValue(true);
          c.onValueReceived.listen((value) {
            setState(() {
              _receivedData = utf8.decode(value);
            });
          });
          break;
        }
      }
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _connected = false;
        _receivedData = '';
      });
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Receive'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isScanning
                  ? null
                  : _connected
                      ? _disconnect
                      : _startScan,
              icon: Icon(_connected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
              label: Text(_connected ? 'Disconnect' : 'Scan & Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _connected ? Colors.redAccent : Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _connectedDevice != null
                  ? 'Connected to: ${_connectedDevice!.name}'
                  : 'Not connected',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _receivedData.isEmpty
                        ? 'No data received yet...'
                        : _receivedData,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
