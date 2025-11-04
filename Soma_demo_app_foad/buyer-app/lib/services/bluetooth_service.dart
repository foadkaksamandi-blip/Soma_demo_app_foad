// File: buyer-app/lib/services/bluetooth_service.dart
import 'dart:async';

class BluetoothService {
  bool _connected = false;
  bool get isConnected => _connected;

  Future<void> connectToMerchant() async {
    await Future.delayed(const Duration(seconds: 1));
    _connected = true;
  }

  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _connected = false;
  }

  Future<String> sendPayment(int amount) async {
    if (!_connected) throw Exception('Bluetooth not connected');
    await Future.delayed(const Duration(milliseconds: 700));
    return 'TXN-${DateTime.now().millisecondsSinceEpoch}';
  }
}
